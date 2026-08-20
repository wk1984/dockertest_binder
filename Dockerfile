FROM quay.io/jupyter/minimal-notebook

# 设置环境变量，允许 root 用户运行 MPI
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
ARG DEBIAN_FRONTEND=noninteractive

USER root

# 1. 安装基础依赖 (注意这里依然不安装系统的 libproj-dev)
RUN apt-get update -y && \
    apt-get install -y wget curl git nco build-essential gfortran \
    libreadline-dev m4 libnetcdf-dev libnetcdff-dev libhdf5-dev \
    libeccodes-dev sqlite3 libsqlite3-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. 编译安装老版本 PROJ (4.9.3)，以提供 proj_api.h
RUN wget https://download.osgeo.org/proj/proj-4.9.3.tar.gz && \
    tar -xzvf proj-4.9.3.tar.gz && \
    cd proj-4.9.3 && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd .. && \
    rm -rf proj-4.9.3 proj-4.9.3.tar.gz

# 3. 下载 CDO 1.7.2 源码并进行编译安装
RUN wget https://code.mpimet.mpg.de/attachments/download/12760/cdo-1.7.2.tar.gz && \
    tar -xzvf cdo-1.7.2.tar.gz && \
    cd cdo-1.7.2 && \
    ./configure --with-netcdf --with-hdf5 --with-eccodes --with-proj=/usr/local \
        CPPFLAGS="-I/usr/include/hdf5/serial" \
        LDFLAGS="-L/usr/lib/x86_64-linux-gnu/hdf5/serial -lhdf5_hl -lhdf5" && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf cdo-1.7.2 cdo-1.7.2.tar.gz

# 4. 验证安装版本
RUN cdo -V

# 5. 使用 conda 安装 R 3.6.x 及 Jupyter R 内核
# - 创建名为 r36 的独立环境防止依赖冲突
# - 安装 r-base=3.6.3 和 r-irkernel
# - 将 R 内核注册到 Jupyter，并创建全局软链接
RUN conda create -y -n r36 -c conda-forge r-base==3.6.3 r-ncdf4 r-raster r-rgdal r-sf r-stringi r-lwgeom r-foreach r-doparallel r-geosphere r-udunits2 r-foreign r-rcolorbrewer r-maps gmt==6.1.1 r-irkernel && \
    conda clean --all -f -y && \
    conda run -n r36 R -e "IRkernel::installspec(user = FALSE)" && \
    ln -s /opt/conda/envs/r36/bin/R /usr/local/bin/R && \
    ln -s /opt/conda/envs/r36/bin/Rscript /usr/local/bin/Rscript
    
USER jovyan

# CMD ["jupyter-lab" ,  "--ip=0.0.0.0"  , "--no-browser" ,  "--allow-root"]