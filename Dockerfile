FROM jupyter/base-notebook:python-3.9

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True

USER root

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
	SITE_SPECIFIC_INCLUDES="-I/usr/include/jsoncpp" \
    OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# 安装编译环境
RUN apt-get update -qqq && apt-get install -y --no-install-recommends -qqq \
    build-essential ca-certificates git nano curl wget sudo \
    libboost-all-dev libjsoncpp-dev liblapacke-dev libnetcdf-dev \
    libreadline-dev netcdf-bin libffi-dev libssl-dev libbz2-dev \
    liblzma-dev libncurses5-dev libsqlite3-dev \
    # libgeos-dev libproj-dev gdal-bin tk-dev \
    && rm -rf /var/lib/apt/lists/*
    
RUN git clone --depth 1 -b v0.8.3 https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git /opt/dvm-dos-tem \
    && cd /opt/dvm-dos-tem \
    && make

RUN pip install matplotlib==3.5.2 numpy==1.22.3 pandas==1.4.2 bokeh==2.4.2 netCDF4==1.5.8 commentjson==0.9.0 ipython==8.10.0 jupyter==1.0.0 lhsmdu==1.1 xarray==2023.1.* pypdf==5.1.* pytest==8.3.5
    
ENV PATH=/opt/dvm-dos-tem:/opt/dvm-dos-tem/scripts:/opt/dvm-dos-tem/scripts/util:$PATH
    
USER jovyan

RUN dvmdostem --sha

CMD ["jupyter-lab" , "--ip=0.0.0.0", "--no-browser"]