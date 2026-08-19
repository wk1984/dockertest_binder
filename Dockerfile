FROM ubuntu:16.04
	
# 设置环境变量，允许 root 用户运行 MPI
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
ARG DEBIAN_FRONTEND=noninteractive

# 安装所有依赖（一次性安装，减少层数）
RUN apt-get update -y && \
    apt-get install -y wget curl git cdo

RUN wget --quiet https://github.com/conda-forge/miniforge/releases/download/4.12.0-0/Mambaforge-4.12.0-0-Linux-x86_64.sh -O ~/miniconda.sh \
    && /bin/bash ~/miniconda.sh -b -p /opt/miniconda3 \
    && rm ~/miniconda.sh \
    && ln -s /opt/miniconda3/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". /opt/miniconda3/etc/profile.d/conda.sh" >> ~/.bashrc

ENV PATH=/opt/miniconda3/bin:${PATH}
ARG PATH=/opt/miniconda3/bin:${PATH}

RUN . /root/.bashrc \
    && /opt/miniconda3/bin/conda init bash \
    && conda info --envs \
    && conda create -n R36 -c conda-forge \
    && conda activate R36 \
    && mamba install -c conda-forge ipykernel r-base==3.6.3 r-ncdf4 r-raster r-rgdal r-sf r-stringi r-lwgeom r-foreach r-doparallel r-geosphere r-udunits2 r-foreign r-rcolorbrewer r-maps gmt==6.1.1 -y \
    && conda clean --all