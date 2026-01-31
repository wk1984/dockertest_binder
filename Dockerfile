# ==========================================
# 第一阶段：编译 (Builder Stage)
# ==========================================
FROM jupyter/julia-notebook:x86_64-python-3.11.6 AS builder

# 避免交互式提示
ARG DEBIAN_FRONTEND=noninteractive
ENV SITE_SPECIFIC_INCLUDES="-I/usr/include/jsoncpp"

USER root

# 安装必要的编译工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    git \
    libboost-all-dev \
    libreadline-dev \
    libjsoncpp-dev \
    liblapacke-dev \
    libnetcdf-dev \
    && rm -rf /var/lib/apt/lists/*

# 克隆源码并编译
WORKDIR /build
RUN git clone --depth 1 -b v0.8.3 https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git \
    && cd dvm-dos-tem \
    && make
    
# 在 builder 阶段：自动搜集所有依赖库
RUN mkdir -p /deps && \
    ldd /build/dvm-dos-tem/dvmdostem | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v --parents '{}' /deps
    
RUN ls /deps

# ==========================================
# 第二阶段：运行 (Runtime Stage)
# ==========================================
FROM jupyter/julia-notebook:x86_64-python-3.11.6

# 基础环境变量设置
ENV TZ=Etc/UTC \
    SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True \
    PATH=/opt/dvm-dos-tem:/opt/dvm-dos-tem/scripts:/opt/dvm-dos-tem/scripts/util:$PATH \
    OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# WORKDIR /opt/dvm-dos-tem

USER root

# 1. 只安装运行所需的最小化运行时库
# 2. 这里的包名针对 Ubuntu 24.04 进行了优化
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
# libnetcdf-dev libboost-all-dev libjsoncpp-dev \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 从编译阶段拷贝构建好的整个目录（包含二进制文件和脚本）
COPY --from=builder /build/dvm-dos-tem /opt/dvm-dos-tem

COPY --from=builder /usr/lib/x86_64-linux-gnu/liblapacke.so.3 /usr/lib/x86_64-linux-gnu/liblapacke.so.3
COPY --from=builder /usr/lib/x86_64-linux-gnu/libnetcdf.so.19 /usr/lib/x86_64-linux-gnu/libnetcdf.so.19
COPY --from=builder /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.74.0 /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.74.0
COPY --from=builder /usr/lib/x86_64-linux-gnu/libboost_program_options.so.1.74.0 /usr/lib/x86_64-linux-gnu/libboost_program_options.so.1.74.0
COPY --from=builder /usr/lib/x86_64-linux-gnu/libboost_thread.so.1.74.0 /usr/lib/x86_64-linux-gnu/libboost_thread.so.1.74.0
COPY --from=builder /usr/lib/x86_64-linux-gnu/libboost_log.so.1.74.0 /usr/lib/x86_64-linux-gnu/libboost_log.so.1.74.0
COPY --from=builder /usr/lib/x86_64-linux-gnu/libjsoncpp.so.25 /usr/lib/x86_64-linux-gnu/libjsoncpp.so.25
COPY --from=builder /usr/lib/x86_64-linux-gnu/libhdf5_serial_hl.so.100 /usr/lib/x86_64-linux-gnu/libhdf5_serial_hl.so.100
COPY --from=builder /usr/lib/x86_64-linux-gnu/libhdf5_serial.so.103 /usr/lib/x86_64-linux-gnu/libhdf5_serial.so.103
COPY --from=builder /usr/lib/x86_64-linux-gnu/libblas.so.3 /usr/lib/x86_64-linux-gnu/libblas.so.3
COPY --from=builder /usr/lib/x86_64-linux-gnu/liblapack.so.3 /usr/lib/x86_64-linux-gnu/liblapack.so.3
COPY --from=builder /usr/lib/x86_64-linux-gnu/libtmglib.so.3 /usr/lib/x86_64-linux-gnu/libtmglib.so.3
COPY --from=builder /usr/lib/x86_64-linux-gnu/libsz.so.2 /usr/lib/x86_64-linux-gnu/libsz.so.2
COPY --from=builder /usr/lib/x86_64-linux-gnu/libgfortran.so.5 /usr/lib/x86_64-linux-gnu/libgfortran.so.5
COPY --from=builder /usr/lib/x86_64-linux-gnu/libaec.so.0 /usr/lib/x86_64-linux-gnu/libaec.so.0
COPY --from=builder /usr/lib/x86_64-linux-gnu/libquadmath.so.0 /usr/lib/x86_64-linux-gnu/libquadmath.so.0

# 删除构建过程中产生的中间目标文件 (.o) 以进一步瘦身
RUN find /opt/dvm-dos-tem -name "*.o" -type f -delete

RUN which dvmdostem \
    && dvmdostem --sha

# CMD ["/bin/bash"]