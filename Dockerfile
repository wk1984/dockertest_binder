# =========================================================================
# Stage 1: "builder" - 编译阶段
# =========================================================================
FROM ubuntu:jammy AS builder

# 设置环境变量，允许 root 用户运行 MPI [cite: 1]
ENV OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
    DEBIAN_FRONTEND=noninteractive \
    SITE_SPECIFIC_INCLUDES="-I/usr/include/jsoncpp" \
    SITE_SPECIFIC_LIBS="-I/usr/lib" \
    TZ=Etc/UTC \
    NETCDF=/usr

# 安装基础编译环境 [cite: 1, 2, 5]
RUN apt-get update -qqq && apt-get install -y --no-install-recommends -qqq \
    build-essential ca-certificates git nano curl wget sudo \
    libboost-all-dev libjsoncpp-dev liblapacke-dev libnetcdf-dev \
    libreadline-dev netcdf-bin libffi-dev libssl-dev libbz2-dev \
    liblzma-dev libncurses5-dev libsqlite3-dev \
    # libproj-dev gdal-bin libgeos-dev doxygen graphviz gdb vim tk-dev \
    && rm -rf /var/lib/apt/lists/*

# 克隆并编译模型 [cite: 2]
RUN git clone --depth 1 -b v0.8.3 https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git /opt/dvm-dos-tem \
    && cd /opt/dvm-dos-tem \
    && make

# 配置用户和 Python 环境 
RUN useradd -m -s /bin/bash user && echo "user:111" | chpasswd
USER user
ENV HOME=/home/user \
    PYENV_ROOT=/home/user/.pyenv
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

RUN git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv \
    && git clone https://github.com/pyenv/pyenv-virtualenv.git $HOME/.pyenv/plugins/pyenv-virtualenv \
    && pyenv install 3.9.25 \
    && pyenv global 3.9.25 \
    && pip install -U pip pipenv

# --- 修复位置：改用 RUN cp 处理镜像内已有的文件 ---
RUN cp /opt/dvm-dos-tem/requirements_general_dev.txt /tmp/requirements.txt \
    && pip install -r /tmp/requirements.txt \
#    && pip install cartopy==0.21.0 regionmask jupyterlab \
	&& pip install jupyterlab \
    && pip cache purge

# =========================================================================
# Stage 2: "Final Image" - 运行阶段
# =========================================================================
FROM ubuntu:jammy

ARG DEBIAN_FRONTEND=noninteractive
ENV SITE_SPECIFIC_INCLUDES="-I/usr/include/jsoncpp" \
    SITE_SPECIFIC_LIBS="-I/usr/lib" \
    HOME=/home/user \
    PYENV_ROOT=/home/user/.pyenv \
    PYTHONPATH="/opt/dvm-dos-tem/scripts:/opt/dvm-dos-tem/" \
    JULIA_PATH="/opt/julia-1.9"

ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:/opt/dvm-dos-tem:/opt/dvm-dos-tem/scripts:/opt/dvm-dos-tem/scripts/util:/opt/dvm-dos-tem/mads_calibration:$JULIA_PATH/bin:$PATH

# 安装运行时必要的共享库 [cite: 5]
RUN apt-get update && apt-get install -y --no-install-recommends \
    libboost-program-options-dev libboost-all-dev libjsoncpp25 liblapacke libnetcdf19 \
    # libgeos-c1v5 libproj22 gdal-bin \
    libzmq3-dev ca-certificates \
    sudo wget curl git nano \
    && rm -rf /var/lib/apt/lists/* && ldconfig

# 创建用户 [cite: 6]
RUN useradd -m -s /bin/bash user && echo "user:111" | chpasswd && usermod -aG sudo user

# 从 builder 拷贝编译好的模型，使用 --chown 优化权限
COPY --from=builder --chown=user:user /opt/dvm-dos-tem /opt/dvm-dos-tem
COPY --from=builder --chown=user:user $HOME/.pyenv $HOME/.pyenv

# 安装 Julia 1.9 (LTS版本)
RUN mkdir -p $JULIA_PATH \
    && wget --no-check-certificate --quiet https://julialang-s3.julialang.org/bin/linux/x64/1.9/julia-1.9.3-linux-x86_64.tar.gz \
    && tar -xzf julia-1.9.3-linux-x86_64.tar.gz -C $JULIA_PATH --strip-components=1 \
    && rm julia-1.9.3-linux-x86_64.tar.gz

USER user
WORKDIR $HOME

# 修复后的 Julia 包安装指令：
# 1. 移除了非标准的 quiet 参数
# 2. 锁定了 Mads 版本以保证兼容性 
# 3. 显式执行 Pkg.build("PyCall") 确保其链接到正确的 Python
RUN julia -e 'using Pkg; \
    Pkg.add([ \
        PackageSpec(name="Mads", version="1.3.10"), \
        PackageSpec(name="PyCall"), \
        PackageSpec(name="DataFrames"), \
        PackageSpec(name="DataStructures"), \
        PackageSpec(name="CSV"), \
        PackageSpec(name="YAML"), \
        PackageSpec(name="IJulia") \
    ]); \
    Pkg.build("PyCall"); \
    Pkg.precompile()'
	
# 配置 Jupyter 环境 [cite: 4]
RUN mkdir -p $HOME/.jupyter \
    && cp /opt/dvm-dos-tem/special_configurations/jupyter_notebook_config.py $HOME/.jupyter/jupyter_notebook_config.py \
    && echo "c.ServerApp.password = u'$(python -c "from jupyter_server.auth import passwd; print(passwd('123456'))")'" >> $HOME/.jupyter/jupyter_notebook_config.py \
    && echo "c.ServerApp.terminado_settings = { \"shell_command\": [\"/usr/bin/bash\"] }" >>  $HOME/.jupyter/jupyter_notebook_config.py \
    && echo "c.ServerApp.allow_origin = '*'\nc.ServerApp.allow_remote_access = True\nc.ServerApp.ip = '*'\nc.ServerApp.open_browser = False" >> $HOME/.jupyter/jupyter_notebook_config.py

# 必须要修改权限，否则JUPYTER停止后不能够重新启动
USER root
RUN chown -R user:user $HOME/
RUN chmod -R u+rwx $HOME/

RUN chown -R user:user /work
RUN chmod -R u+rwx /work

# 设置最终工作目录
USER user
WORKDIR /work
EXPOSE 8888

CMD ["jupyter-lab" , "--ip=0.0.0.0", "--no-browser"]

# docker run -it --name dvmdostem -v $PWD:/work:delegated -p 9899:8888 wk1984/dvmdostem:v0.8.3