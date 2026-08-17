# 使用官方的 R 3.6.1
# FROM jupyter/r-notebook:ad3574d3c5c7
# FROM jupyter/r-notebook:7a0c7325e470
# FROM jupyter/r-notebook:e00fd05364df
# FROM jupyter/r-notebook:29e069665f5f
# FROM jupyter/r-notebook:1c8073a927aa
# FROM jupyter/r-notebook:31b807ec9e83

# 使用官方的 R 3.6.2
FROM jupyter/r-notebook:8882c505faa8

# 使用官方的 R 3.6.3
# FROM jupyter/r-notebook:04f7f60d34a6

# 设置环境变量，避免 apt 安装时出现交互提示
ENV DEBIAN_FRONTEND=noninteractive

RUN R --version

# -------------------------------------------------------------
# 切换到 root 用户以安装 LandInG 空间 R 包所需的底层系统级依赖
USER root

# 安装 GDAL, GEOS, PROJ, NetCDF 以及 udunits2 (sf的单位换算依赖)
RUN apt-get update && apt-get install -y \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libnetcdf-dev \
    libudunits2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 将 R 的默认源修改为 Posit Package Manager 的 2020-02-28 历史快照
# 在 jupyter/r-notebook (基于conda) 的环境中，配置文件位于此处
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/2020-02-28/"))' > /opt/conda/lib/R/etc/Rprofile.site

# -------------------------------------------------------------
# 切换回默认的非 root 用户 jovyan 进行 R 包的安装
USER $NB_UID

# 安装 LandInG 依赖的核心 R 包
RUN R -e "install.packages(c('ncdf4', 'raster', 'rgdal', 'sf', 'lwgeom', 'foreach', 'doParallel'))"

# 设置工作目录
WORKDIR /workspace

# 暴露 JupyterLab 默认端口
EXPOSE 8888

# 启动 JupyterLab，允许 root 运行，并为了本地开发方便暂时关闭 token 验证
# CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''"]