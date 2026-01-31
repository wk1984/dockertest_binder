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

WORKDIR /opt/dvm-dos-tem

USER root

# 1. 只安装运行所需的最小化运行时库
# 2. 这里的包名针对 Ubuntu 24.04 进行了优化
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libnetcdf-dev libboost-all-dev libjsoncpp-dev \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 从编译阶段拷贝构建好的整个目录（包含二进制文件和脚本）
COPY --from=builder /build/dvm-dos-tem /opt/dvm-dos-tem

# 删除构建过程中产生的中间目标文件 (.o) 以进一步瘦身
RUN find /opt/dvm-dos-tem -name "*.o" -type f -delete

RUN which dvmdostem \
    && dvmdostem --sha

# CMD ["/bin/bash"]