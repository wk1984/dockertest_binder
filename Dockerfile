FROM quay.io/jupyter/minimal-notebook

# 1. 声明 Binder 需要的用户参数
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER=${NB_USER}
ENV NB_UID=${NB_UID}
ENV HOME=/home/${NB_USER}

# 设置环境变量，允许 root 用户运行 MPI
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
ARG DEBIAN_FRONTEND=noninteractive

USER root

# 2. 安装基础依赖
RUN apt-get update -y && \
    apt-get install -y wget curl git nco nano build-essential gfortran \
    libreadline-dev m4 libnetcdf-dev libnetcdff-dev libhdf5-dev \
    libeccodes-dev sqlite3 libsqlite3-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. 编译安装老版本 PROJ (4.9.3)
RUN wget https://download.osgeo.org/proj/proj-4.9.3.tar.gz && \
    tar -xzvf proj-4.9.3.tar.gz && \
    cd proj-4.9.3 && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd .. && \
    rm -rf proj-4.9.3 proj-4.9.3.tar.gz

# 4. 编译安装 CDO 1.7.2
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

# 5. 验证安装版本
RUN cdo -V

# 6. 安装 R 3.6.x 及 Jupyter R 内核
RUN conda create -y -n r36 -c conda-forge r-base=3.6.3 r-irkernel r-ncdf4 r-raster r-rgdal r-sf r-stringi r-lwgeom r-foreach r-doparallel r-geosphere r-udunits2 r-foreign r-rcolorbrewer r-maps r-abind r-data.table gmt==6.1.1 && \
    conda clean --all -f -y && \
    conda run -n r36 R -e "IRkernel::installspec(user = FALSE)" && \
    ln -s /opt/conda/envs/r36/bin/R /usr/local/bin/R && \
    ln -s /opt/conda/envs/r36/bin/Rscript /usr/local/bin/Rscript

# 7. 确保主目录归属于 Binder 用户 (非常关键的 Binder 配置)
RUN chown -R ${NB_UID} ${HOME}

# 8. 切换回普通用户，不需要 CMD，Binder 会自动接管启动
USER ${NB_USER}

WORKDIR /work

RUN git clone https://github.com/PIK-LPJmL/LandInG.git

