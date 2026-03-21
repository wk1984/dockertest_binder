# ==========================================
# 第一阶段：编译 (Builder Stage)
# ==========================================
FROM ubuntu:22.04 AS builder

ENV TZ=Etc/UTC \
    GIT_PROXY=https://gh-proxy.com/ \
    OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
	DEBIAN_FRONTEND=noninteractive \
	DEBCONF_NONINTERACTIVE_SEEN=true \
	SITE_SPECIFIC_INCLUDES="-I/usr/include/jsoncpp" \
	SITE_SPECIFIC_LIBS="-I/usr/lib" \
	PYENV_ROOT=/home/ddt_user/.pyenv \
    PATH=/opt/dvm-dos-tem:/opt/dvm-dos-tem/scripts:/opt/dvm-dos-tem/scripts/util:/opt/dvm-dos-tem/scripts/viewers:/opt/julia-1.7.3/bin:$PATH \
    JULIA_PKG_SERVER="https://mirrors.ustc.edu.cn/julia" \
	PYTHONPATH="/opt/dvm-dos-tem/scripts:/opt/dvm-dos-tem/scripts/viewers:/opt/dvm-dos-tem/scripts/util:/opt/dvm-dos-tem/mads_calibration"
		
RUN sed -i "s@http://.*.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list

# 安装必要的编译工具
# >>> 非并行版本 >>>
RUN apt-get update -y --fix-missing \
    && apt-get install -y --no-install-recommends \
       libreadline-dev  language-pack-en \
       liblapacke liblapacke-dev \
       libboost-thread-dev libboost-system-dev libboost-program-options-dev libboost-log-dev \
	   libhdf5-dev libnetcdf-dev libjsoncpp-dev \
       libffi-dev libssl-dev libbz2-dev liblzma-dev libncurses5-dev \
       libncursesw5-dev libsqlite3-dev \
       g++ make patch \
       ca-certificates \
	   git wget curl nano sudo \
    && rm -rf /var/lib/apt/lists/*

# 克隆源码并编译

RUN git clone -b v0.8.3 ${GIT_PROXY}https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git /opt/dvm-dos-tem \
    && cd /opt/dvm-dos-tem \
    && make

RUN cd /opt \
    && wget --quiet https://julialang-s3.julialang.org/bin/linux/x64/1.7/julia-1.7.3-linux-x86_64.tar.gz \
    && tar -xzf julia-1.7.3-linux-x86_64.tar.gz \
    && rm julia-1.7.3-linux-x86_64.tar.gz
	
# ===== install python pkgs =====

ENV HOME=/home/ddt_user

RUN git clone ${GIT_PROXY}https://github.com/pyenv/pyenv.git $HOME/.pyenv
ENV PYENV_ROOT=$HOME/.pyenv
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
RUN git clone ${GIT_PROXY}https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
RUN pyenv install 3.11.15
RUN pyenv global 3.11.15
RUN pyenv rehash
RUN python --version
	
RUN dvmdostem --sha

# ==========================================
# 第二阶段：运行环境 (Final Stage)
# ==========================================

FROM ubuntu:22.04

ENV TZ=Etc/UTC \
    GIT_PROXY=https://gh-proxy.com/ \
    OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
	DEBIAN_FRONTEND=noninteractive \
	DEBCONF_NONINTERACTIVE_SEEN=true \
	SITE_SPECIFIC_INCLUDES="-I/usr/include/jsoncpp" \
	SITE_SPECIFIC_LIBS="-I/usr/lib" \
	PYENV_ROOT=/home/ddt_user/.pyenv \
    PATH=/opt/dvm-dos-tem:/opt/dvm-dos-tem/scripts:/opt/dvm-dos-tem/scripts/util:/opt/dvm-dos-tem/scripts/viewers:/opt/julia-1.7.3/bin:$PATH \
    JULIA_PKG_SERVER="https://mirrors.ustc.edu.cn/julia" \
	PYTHONPATH="/opt/dvm-dos-tem/scripts:/opt/dvm-dos-tem/scripts/viewers:/opt/dvm-dos-tem/scripts/util:/opt/dvm-dos-tem/mads_calibration"

RUN sed -i "s@http://.*.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list

RUN apt-get update -y --fix-missing

RUN apt-get install -y --no-install-recommends \
       libreadline-dev   \
       liblapacke libnetcdf-dev libboost-thread-dev libboost-system-dev libboost-program-options-dev libboost-log-dev \
	   libjsoncpp-dev liblzma-dev libsqlite3-dev \
       language-pack-en \
       ca-certificates \
	   git wget nano sudo \
    && rm -rf /var/lib/apt/lists/*

# 复制编译好的程序和 Julia
COPY --from=builder /opt/dvm-dos-tem /opt/dvm-dos-tem
COPY --from=builder /opt/julia-1.7.3 /opt/julia-1.7.3
COPY --from=builder /home/ddt_user/.pyenv /home/ddt_user/.pyenv

# 2. 创建用户组和用户
RUN useradd -m -s /bin/bash ddt_user
RUN echo "ddt_user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# HAVE to CHANGE permission of the home path, otherwise, You can not save any files.
RUN chown -R ddt_user /home/ddt_user

# ===== MOVE TO USER =====

USER ddt_user
ENV HOME=/home/ddt_user

RUN dvmdostem --sha

# ===== install python pkgs =====

ENV PYENV_ROOT=$HOME/.pyenv
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

RUN pyenv rehash
RUN python --version
RUN pip install --no-cache-dir -U pip pipenv -i https://mirror.sjtu.edu.cn/pypi/web/simple
RUN pip install --no-cache-dir matplotlib numpy pandas bokeh netCDF4 commentjson ipython jupyter lhsmdu xarray scikit-learn pyyaml scipy -i https://mirror.sjtu.edu.cn/pypi/web/simple

RUN jupyter-lab --version

# install julia pkgs ===========

ENV PYTHON=$HOME/.pyenv/shims/python

RUN echo 'using Pkg; Pkg.add(name="Mads", version="1.3.10")' | julia
RUN echo 'using Pkg; Pkg.add("PyCall")' | julia
RUN echo 'using Pkg; Pkg.add("DataFrames")' | julia
RUN echo 'using Pkg; Pkg.add("DataStructures")' | julia
RUN echo 'using Pkg; Pkg.add("CSV")' | julia
RUN echo 'using Pkg; Pkg.add("YAML")' | julia
RUN echo 'using Pkg; Pkg.add("IJulia")' | julia
RUN echo 'using Pkg; Pkg.precompile()' | julia
RUN echo 'using Pkg; Pkg.build("PyCall")' | julia
RUN echo 'using Pkg; Pkg.gc()' | julia

# configure jupyter notebook ==========

ARG dump_file=$HOME/.jupyter/jupyter_lab_config.py

RUN jupyter-lab --generate-config
RUN python -c "from jupyter_server.auth import passwd; print(\"c.ServerApp.password = u'\" +  passwd('123456') + \"'\")" >> $dump_file

RUN echo c.ServerApp.allow_origin = \'*\'  >> $dump_file
RUN echo c.ServerApp.allow_remote_access = True >> $dump_file
RUN echo c.ServerApp.ip = \'*\' >> $dump_file
RUN echo c.ServerApp.open_browser = False >> $dump_file
RUN echo "c.ServerApp.terminado_settings = { \"shell_command\": [\"/usr/bin/bash\"] }" >> $dump_file

CMD ["jupyter-lab" ,  "--ip=0.0.0.0"  , "--no-browser", "--allow-root"]