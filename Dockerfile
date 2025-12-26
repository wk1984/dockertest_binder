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

# 2. 下载并安装 LibTorch (以 2.0.1 CPU 版本为例)
# 注意：如果你的模型是用 GPU 训练的，建议下载对应的 CUDA 版本
RUN wget https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-2.0.1%2Bcpu.zip -O /tmp/libtorch.zip && \
    unzip /tmp/libtorch.zip -d /opt/ && \
    rm /tmp/libtorch.zip

# 设置 LibTorch 环境变量
ENV TORCH_PATH=/opt/libtorch
ENV LD_LIBRARY_PATH=/opt/libtorch/lib:$LD_LIBRARY_PATH

# 3. 克隆代码库
RUN git clone https://github.com/dudek313/torchclim.git \
    && cd torchclim/torch-wrapper \
    && ./env/install-deps.sh