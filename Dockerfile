# FROM jupyter/base-notebook:python-3.9
FROM jupyter/julia-notebook:x86_64-julia-1.9.3

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True

USER root

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
	SITE_SPECIFIC_INCLUDES="-I/usr/include/jsoncpp" \
    OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
    PATH=/opt/dvm-dos-tem/pyddt/src/pyddt/util/:/opt/dvm-dos-tem/pyddt/src/pyddt/viewers/:/opt/dvm-dos-tem/pyddt/src/pyddt/calibration/:/opt/dvm-dos-tem:/opt/dvm-dos-tem/scripts:/opt/dvm-dos-tem/scripts/util:/opt/dvm-dos-tem/scripts/viewers:$PATH

# 安装编译环境
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

# numpy==1.22.3 pandas matplotlib xarray netcdf4 commentjson pyyaml scipy lhsmdu scikit-learn bokeh jupyterlab
    
RUN git clone https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git /opt/dvm-dos-tem \
    && cd /opt/dvm-dos-tem \
    && make

USER jovyan

RUN pip install matplotlib==3.8.4 numpy==1.22.3 pandas==1.5.1 bokeh==3.9.0 netCDF4==1.7.4 commentjson==0.9.0 ipython jupyter==1.1.1 lhsmdu==1.1 xarray==2023.12.0 scikit-learn==1.7.2 pyyaml scipy==1.11.4 \
    &&  cd /opt/dvm-dos-tem \
    && pip install -e /opt/dvm-dos-tem/pyddt/

RUN echo 'using Pkg; Pkg.add(name="Mads", version="1.3.10")' | julia
RUN echo 'using Pkg; Pkg.add("PyCall")' | julia
RUN echo 'using Pkg; Pkg.add("DataFrames")' | julia
RUN echo 'using Pkg; Pkg.add("DataStructures")' | julia
RUN echo 'using Pkg; Pkg.add("CSV")' | julia
RUN echo 'using Pkg; Pkg.add("YAML")' | julia

RUN dvmdostem --sha

CMD ["jupyter-lab" , "--ip=0.0.0.0", "--no-browser"]