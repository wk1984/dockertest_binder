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
	PYENV_ROOT=/root/.pyenv \
    PATH=/opt/dvm-dos-tem:/opt/dvm-dos-tem/scripts:/opt/dvm-dos-tem/scripts/util:/opt/dvm-dos-tem/scripts/viewers:/opt/julia-1.7.3/bin:/root/.pyenv/shims:/root/.pyenv/bin::$PATH \
#     JULIA_PKG_SERVER="https://mirrors.ustc.edu.cn/julia" \
	PYTHONPATH="/opt/dvm-dos-tem/scripts:/opt/dvm-dos-tem/scripts/viewers:/opt/dvm-dos-tem/scripts/util:/opt/dvm-dos-tem/mads_calibration"
		
#RUN sed -i 's@http://.*archive.ubuntu.com@https://mirrors.aliyun.com/@g' /etc/apt/sources.list
#RUN sed -i 's@http://.*security.ubuntu.com@https://mirrors.aliyun.com/@g' /etc/apt/sources.list

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
       g++ make \
       ca-certificates \
	   git wget curl nano \
    && rm -rf /var/lib/apt/lists/*

# 克隆源码并编译
WORKDIR /opt

# install python pkgs ==========

RUN mkdir -p /root/.jupyter
RUN git clone https://github.com/pyenv/pyenv.git /root/.pyenv
RUN git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
RUN pyenv install 3.10.20
RUN pyenv global 3.10.20
RUN pyenv rehash
# RUN python --version
RUN pip install -U pip pipenv
RUN pip install matplotlib==3.8.4 numpy==1.22.3 pandas==1.5.1 bokeh==3.9.0 netCDF4==1.7.4 commentjson==0.9.0 ipython jupyter==1.1.1 lhsmdu==1.1 xarray==2023.12.0 scikit-learn==1.7.2 pyyaml scipy==1.11.4

RUN git clone -b v0.8.3 https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git \
    && cd dvm-dos-tem \
    && make
	
RUN dvmdostem --sha \
    && jupyter-lab --version

# install julia pkgs ===========

RUN wget --quiet https://julialang-s3.julialang.org/bin/linux/x64/1.7/julia-1.7.3-linux-x86_64.tar.gz \
    && tar -xzf julia-1.7.3-linux-x86_64.tar.gz \
    && rm julia-1.7.3-linux-x86_64.tar.gz
    
RUN echo 'using Pkg; Pkg.add(name="Mads", version="1.3.10")' | julia
RUN echo 'using Pkg; Pkg.add("PyCall")' | julia
RUN echo 'using Pkg; Pkg.add("DataFrames")' | julia
RUN echo 'using Pkg; Pkg.add("DataStructures")' | julia
RUN echo 'using Pkg; Pkg.add("CSV")' | julia
RUN echo 'using Pkg; Pkg.add("YAML")' | julia
RUN echo 'using Pkg; Pkg.add("IJulia")' | julia

RUN echo 'using Pkg; Pkg.gc()' | julia

# configure jupyter notebook ==========

#ARG dump_file=/root/.jupyter/jupyter_lab_config.py

#RUN jupyter-lab --generate-config
#RUN python -c "from jupyter_server.auth import passwd; print(\"c.ServerApp.password = u'\" +  passwd('123456') + \"'\")" >> $dump_file

#RUN echo c.ServerApp.allow_origin = \'*\'  >> $dump_file
#RUN echo c.ServerApp.allow_remote_access = True >> $dump_file
#RUN echo c.ServerApp.ip = \'*\' >> $dump_file
#RUN echo c.ServerApp.open_browser = False >> $dump_file
#RUN echo "c.ServerApp.terminado_settings = { \"shell_command\": [\"/usr/bin/bash\"] }" >> $dump_file

CMD ["jupyter-lab" ,  "--ip=0.0.0.0"  , "--no-browser", "--allow-root"]