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
    
ENV PATH=/opt/dvm-dos-tem:/opt/dvm-dos-tem/scripts:$PATH
    
USER jovyan

RUN dvmdostem --sha