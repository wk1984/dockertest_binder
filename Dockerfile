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

FROM condaforge/mambaforge:4.9.2-5

# 设置环境变量，避免 apt 安装时出现交互提示
ENV DEBIAN_FRONTEND=noninteractive

RUN mamba install --quiet --yes -c conda-forge \
    'jupyter' \
    'r-base=3.6.2' \
    'r-ncdf4' \
    'r-raster' \
    'r-rgdal' \
    'r-sf' \
	'r-stringi' \
    'r-lwgeom' \
    'r-foreach' \
    'r-doparallel' \
	'r-geoshere' \
	'r-udunits2' \
    && conda clean --all -f -y

# 设置工作目录
WORKDIR /workspace

# 暴露 JupyterLab 默认端口
EXPOSE 8888

# 启动 JupyterLab，允许 root 运行，并为了本地开发方便暂时关闭 token 验证
# CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''"]
