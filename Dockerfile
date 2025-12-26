# 使用 Ubuntu 作为基镜像
FROM ubuntu:22.04

# 设置环境变量，避免交互式安装时的提示
ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装基础编译工具和依赖项
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    unzip \
    gfortran \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 设置 LibTorch 环境变量
ENV TORCH_PATH=/opt/libtorch
ENV PATH_TO_LIBTORCH=$SCRIPT_DIR/libtorch
ENV LD_LIBRARY_PATH=$PATH_TO_LIBTORCH/lib:$LD_LIBRARY_PATH

# 3. 克隆代码库
RUN git clone https://github.com/dudek313/torchclim.git \
    && cd torchclim/torch-wrapper \
    && ./env/install-deps.sh \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_PREFIX_PATH=$PATH_TO_LIBTORCH ..