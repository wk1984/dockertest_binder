# 使用 Ubuntu 20.04 作为基础镜像，它对现代编译器支持良好
FROM ubuntu:20.04

# 设置环境变量，避免交互式安装提示
ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装系统级依赖
# 包括：C++/Fortran 编译器 (GCM 开发必需)、CMake、MPI (并行计算需求)、Git、Wget 和解压工具
RUN apt-get update && apt-get install -y \
    build-essential \
    gfortran \
    cmake \
    libopenmpi-dev \
    git \
    wget \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2. 下载并安装 LibTorch (CPU 版本示例)
# TorchClim 依赖 LibTorch 来执行 AI 模型的推理
# 如果你有 GPU 需求，需要更换为支持 CUDA 的 LibTorch 链接
WORKDIR /opt
RUN wget https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-2.1.0%2Bcpu.zip \
    && unzip libtorch-shared-with-deps-2.1.0+cpu.zip \
    && rm libtorch-shared-with-deps-2.1.0+cpu.zip

# 设置 LibTorch 相关的环境变量，以便编译器能找到它
ENV LIBTORCH_PATH=/opt/libtorch
ENV PATH_TO_LIBTORCH=/opt/libtorch
ENV LD_LIBRARY_PATH=/opt/libtorch/lib:$LD_LIBRARY_PATH

# 3. 克隆 TorchClim 源代码
WORKDIR /app
RUN git clone https://github.com/dudek313/torchclim.git .

RUN cd torch-wrapper \
    && mkdir build \
    && ./build.sh

# 4. 编译 TorchClim 插件
# 这里主要编译的是共享库 (shared object)，它将被 GCM 调用
# RUN mkdir build && cd build \
#     && cmake -DCMAKE_PREFIX_PATH=$LIBTORCH_PATH .. \
#     && make -j$(nproc)
# 
# 5. 设置运行环境
# 为了方便后续 GIPL 或 CESM 链接，我们将库路径暴露出来
# ENV TORCHCLIM_LIB_PATH=/app/build