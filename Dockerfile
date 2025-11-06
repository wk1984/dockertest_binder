FROM ubuntu:jammy

# 设置环境变量，允许 root 用户运行 MPI
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# 设置非交互式前端，避免安装过程中的交互提示
ARG DEBIAN_FRONTEND=noninteractive

ENV SITE_SPECIFIC_INCLUDES="-I/usr/include/jsoncpp"
ENV SITE_SPECIFIC_LIBS="-I/usr/lib"

# 设置时区和 NetCDF 路径
ENV TZ=Etc/UTC
ENV NETCDF=/usr

# 安装所有构建时依赖，使用 --no-install-recommends 减少不必要的包安装
RUN apt-get update -y --fix-missing \
    && apt-get install -y --no-install-recommends \
       build-essential ca-certificates doxygen graphviz gdb gdbserver git wget curl \
       libboost-all-dev libjsoncpp-dev liblapacke liblapacke-dev libreadline-dev nano \
       openmpi-bin libopenmpi-dev \
       libboost-mpi-dev libhdf5-openmpi-dev \
       libffi-dev libssl-dev libbz2-dev liblzma-dev libncurses5-dev \
       libncursesw5-dev libsqlite3-dev llvm python3-openssl tk-dev \
       xz-utils zlib1g-dev libgeos-dev \
    && rm -rf /var/lib/apt/lists/*

# 设置编译器环境变量
ENV CC=mpicc
ENV CXX=mpicxx
ENV FC=mpif90
ENV F77=mpif77

# 设置 NetCDF 版本
ENV NETCDF_C_VERSION=4.4.1.1

# 创建临时构建目录
WORKDIR /tmp/build

# 下载、编译并安装并行 NetCDF
RUN wget --no-check-certificate https://gfd-dennou.org/library/netcdf/unidata-mirror/netcdf-${NETCDF_C_VERSION}.tar.gz && \
    tar -xzvf netcdf-${NETCDF_C_VERSION}.tar.gz && \
    cd netcdf-${NETCDF_C_VERSION} && \
    CPPFLAGS="-I/usr/include/hdf5/openmpi" \
    LDFLAGS="-L/usr/lib/x86_64-linux-gnu/hdf5/openmpi" \
    ./configure --prefix=/usr/local --enable-parallel-tests && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf netcdf-c-${NETCDF_C_VERSION} v${NETCDF_C_VERSION}.tar.gz
    
# 更新动态链接库缓存
RUN ldconfig

# 克隆 dvm-dos-tem 仓库，使用 --depth 1 进行浅克隆，减小体积
RUN git clone --depth 1 -b v0.8.3 https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git /opt/dvm-dos-tem

# 编译模型
RUN cd /opt/dvm-dos-tem && make USEMPI=true CC=mpic++