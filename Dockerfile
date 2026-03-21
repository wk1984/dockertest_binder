# ==========================================
# 第一阶段：编译 (Builder Stage)
# ==========================================
FROM ubuntu:22.04

ENV TZ=Etc/UTC \
    OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
	DEBIAN_FRONTEND=noninteractive \
	DEBCONF_NONINTERACTIVE_SEEN=true \
	SITE_SPECIFIC_INCLUDES="-I/usr/include/jsoncpp" \
	SITE_SPECIFIC_LIBS="-I/usr/lib" \
	PYENV_ROOT=/home/ddt_user/.pyenv \
    PATH=/opt/dvm-dos-tem:/opt/dvm-dos-tem/scripts:/opt/dvm-dos-tem/scripts/util:/opt/dvm-dos-tem/scripts/viewers:/opt/julia-1.7.3/bin:$PATH \
	PYTHONPATH="/opt/dvm-dos-tem/scripts:/opt/dvm-dos-tem/scripts/viewers:/opt/dvm-dos-tem/scripts/util:/opt/dvm-dos-tem/mads_calibration"

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
	   git wget curl nano \
    && rm -rf /var/lib/apt/lists/*

# 克隆源码并编译

RUN git clone -b v0.8.3 https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git /opt/dvm-dos-tem \
    && cd /opt/dvm-dos-tem \
    && make
	
RUN cd /opt \
    && wget --quiet https://julialang-s3.julialang.org/bin/linux/x64/1.7/julia-1.7.3-linux-x86_64.tar.gz \
    && tar -xzf julia-1.7.3-linux-x86_64.tar.gz \
    && rm julia-1.7.3-linux-x86_64.tar.gz
	
# 2. 创建用户组和用户
RUN useradd -m -s /bin/bash ddt_user
RUN echo "ddt_user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir /work && ln -s /opt/dvm-dos-tem/dvmdostem /work/dvmdostem

# install python pkgs ==========

USER ddt_user
ENV HOME=/home/ddt_user
RUN git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
ENV PYENV_ROOT=$HOME/.pyenv
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
RUN git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
RUN pyenv install 3.8.6
RUN pyenv global 3.8.6
RUN pyenv rehash
RUN python --version
RUN pip install --no-cache-dir -U pip pipenv
RUN pip install --no-cache-dir matplotlib numpy==1.22.3 pandas bokeh netCDF4 commentjson ipython jupyter lhsmdu xarray scikit-learn pyyaml scipy
RUN pyenv rehash

RUN dvmdostem --sha \
    && jupyter-lab --version

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

WORKDIR $HOME

COPY /mads_calibration $HOME/mads_calibration

CMD ["jupyter-lab" ,  "--ip=0.0.0.0"  , "--no-browser"]