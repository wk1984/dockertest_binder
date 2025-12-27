# =========================================================================
# Stage 1: "builder" - 编译阶段
# =========================================================================
FROM ubuntu:jammy AS builder

# 设置环境变量，允许 root 用户运行 MPI [cite: 1]
ENV OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
    DEBIAN_FRONTEND=noninteractive \
    SITE_SPECIFIC_INCLUDES="-I/usr/include/jsoncpp" \
    SITE_SPECIFIC_LIBS="-I/usr/lib" \
    TZ=Etc/UTC \
    NETCDF=/usr

# 安装基础编译环境 [cite: 1, 2, 5]
RUN apt-get update -qqq && apt-get install -y --no-install-recommends -qqq \
    build-essential ca-certificates git vim curl wget sudo \
    libboost-all-dev libjsoncpp-dev liblapacke-dev libnetcdf-dev \
    libreadline-dev netcdf-bin libffi-dev libssl-dev libbz2-dev \
    liblzma-dev libncurses5-dev libsqlite3-dev tk-dev \
	# NOT REQUIRED >>>
    # libproj-dev gdal-bin libgeos-dev graphviz gdb doxygen \
    && rm -rf /var/lib/apt/lists/*

# 克隆并编译模型 [cite: 2]
RUN git clone --depth 1 -b v0.8.3 https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git /opt/dvm-dos-tem \
    && cd /opt/dvm-dos-tem \
    && make