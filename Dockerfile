# 使用 Ubuntu 22.04 作为基础镜像
FROM ubuntu:22.04

# 避免安装过程中的交互式弹窗
ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装系统先决条件
RUN apt-get update && apt-get install -y \
    cmake \
    csh \
    m4 \
    gfortran \
    git \
    build-essential \
    curl \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /opt/cryowrf

# 2. 下载 CRYOWRF v1.0
RUN git clone https://github.com/vsharma-next/CRYOWRF.git .

# 3. 安装本地库 (NetCDF 4.1.3 和 MPICH 3.0.4)
# 注意：脚本通常会修改环境变量，这里我们需要在后续手动设置 ENV
RUN cd libraries && \
    /bin/bash -c "source ./install_libs.sh"

# 4. 设置环境变量 (参考 install_libs.sh 可能设置的路径)
# 根据 WRF 惯例，通常安装在同级目录的本地文件夹中
ENV NETCDF=/opt/cryowrf/libraries/local
ENV PATH=/opt/cryowrf/libraries/local/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/cryowrf/libraries/local/lib:$LD_LIBRARY_PATH

# 5. 安装 meteoio, snowpack 和 coupler
RUN /bin/bash -c "source ./compiler_snow_libs.sh"

# 6. 编译 WRF
# 选用选项 34 (GNU dmpar)，你可以根据需要修改 printf 中的数字
RUN printf "34\n1\n" | ./configure && \
    ./compile em_real -j 8

# 7. 编译 WPS
# 选用选项 2
ENV WRF_DIR=/opt/cryowrf
RUN cd WPS && \
    printf "2\n" | ./configure && \
    ./compile

# 设置默认启动进入 bash
CMD ["/bin/bash"]