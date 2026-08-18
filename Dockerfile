# 使用官方的 R 3.6.1
# FROM jupyter/r-notebook:ad3574d3c5c7
# FROM jupyter/r-notebook:7a0c7325e470
# FROM jupyter/r-notebook:e00fd05364df
# FROM jupyter/r-notebook:29e069665f5f
# FROM jupyter/r-notebook:1c8073a927aa
# FROM jupyter/r-notebook:31b807ec9e83

# 使用官方的 R 3.6.2
# FROM jupyter/r-notebook:8882c505faa8

# 使用官方的 R 3.6.3
# FROM jupyter/r-notebook:04f7f60d34a6

# FROM jupyter/base-notebook:x86_64-ubuntu-22.04

FROM ubuntu:20.04
	
# 设置环境变量，允许 root 用户运行 MPI
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
ARG DEBIAN_FRONTEND=noninteractive
ENV SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True

# 安装所有依赖（一次性安装，减少层数）
RUN apt-get update -y && \
    apt-get install -y wget curl git sudo
    
#=============================================================================================
#  Set up Python Jupyter Environment ...
#=============================================================================================

# ARG url0=https://github.com/conda-forge/miniforge/releases/download/22.9.0-2/Miniforge3-22.9.0-2-Linux-x86_64.sh
ARG url0=https://github.com/conda-forge/miniforge/releases/download/25.9.1-0/Miniforge3-25.9.1-0-Linux-x86_64.sh
# ARG url0=https://github.com/conda-forge/miniforge/releases/download/4.12.0-0/Miniforge3-4.12.0-0-Linux-x86_64.sh

RUN wget --quiet ${url0} -O ~/miniconda.sh \
    && /bin/bash ~/miniconda.sh -b -p /opt/miniconda3 \
    && rm ~/miniconda.sh \
    && ln -s /opt/miniconda3/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". /opt/miniconda3/etc/profile.d/conda.sh" >> ~/.bashrc

ENV PATH=/opt/miniconda3/bin:${PATH}

RUN . /root/.bashrc \
    && /opt/miniconda3/bin/conda init bash \
    && conda info --envs \
	&& conda create -n R36 -c conda-forge \
	&& conda activate R36 \
    && conda install --quiet --yes -c conda-forge \
    'r-base=3.6.2' \
    'r-ncdf4' \
    'r-raster' \
    'r-rgdal' \
    'r-sf' \
	'r-stringi' \
    'r-lwgeom' \
    'r-foreach' \
    'r-doparallel' \
	'r-geosphere' \
	'r-udunits2' \
    && conda clean --all -f -y

# 设置工作目录
WORKDIR /workspace

# 暴露 JupyterLab 默认端口
EXPOSE 8888

# 启动 JupyterLab，允许 root 运行，并为了本地开发方便暂时关闭 token 验证
# CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''"]
