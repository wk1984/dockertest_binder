# 使用 Ubuntu 作为基镜像
# FROM ubuntu:20.04
FROM intel/oneapi-hpckit:2021.4-devel-ubuntu18.04
#FROM intel/oneapi-hpckit:2022.3.1-devel-ubuntu20.04

# 设置环境变量，避免交互式安装时的提示
ENV DEBIAN_FRONTEND=noninteractive

RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | tee /etc/apt/sources.list.d/oneAPI.list

# RUN which ifort

# 1. 安装基础编译工具和依赖项
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    unzip \
    # gfortran \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 设置 LibTorch 环境变量
ENV SCRIPT_DIR=/root/
ENV Torch_DIR=$SCRIPT_DIR/libtorch
ENV PATH_TO_LIBTORCH=$SCRIPT_DIR/libtorch
ENV LD_LIBRARY_PATH=$PATH_TO_LIBTORCH/lib:$LD_LIBRARY_PATH

# 3. 克隆代码库
#RUN pwd
RUN git clone https://github.com/wk1984/torchclim.git

#RUN cd torchclim/torch-wrapper \
#    && ./env/install-deps.sh
#    && mkdir build \
#    && ./build.sh