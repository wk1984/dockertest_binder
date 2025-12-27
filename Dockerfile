# 使用 Ubuntu 作为基镜像
FROM jupyter/base-notebook:ubuntu-20.04
#FROM intel/oneapi-hpckit:2021.4-devel-ubuntu18.04
#FROM intel/oneapi-hpckit:2022.3.1-devel-ubuntu20.04

USER root

# 设置环境变量，避免交互式安装时的提示
ENV DEBIAN_FRONTEND=noninteractive

#RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
#RUN echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | tee /etc/apt/sources.list.d/oneAPI.list

# 1. 安装基础依赖
RUN apt-get update && apt-get install -y \
    wget git unzip cmake \
    gnupg \
    software-properties-common \
    build-essential \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
# 2. 添加 Intel GPG 密钥和 APT 源

RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null \
    | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null \
    && echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main' \
    | tee /etc/apt/sources.list.d/kitware.list >/dev/null \
    && apt-get update && apt-get install -y cmake \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
    | gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
    | tee /etc/apt/sources.list.d/oneAPI.list \
    && apt-get update && apt-get install -y \
    intel-oneapi-compiler-dpcpp-cpp \
    intel-oneapi-compiler-fortran \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
# 3. 下载并安装 LibTorch (CPU 版本)
# 这里以 LibTorch 2.1.0 为例，你可以根据需要更换版本号
# RUN wget https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-2.1.0%2Bcpu.zip -O /tmp/libtorch.zip \
#     && unzip /tmp/libtorch.zip -d /opt \
#     && rm /tmp/libtorch.zip

# 4. 配置环境变量

ENV SCRIPT_DIR=/home/jovyan/torchclim/torch-wrapper/env
ENV Torch_DIR=$SCRIPT_DIR/libtorch
ENV PATH_TO_LIBTORCH=$LIBTORCH_ROOT
ENV CMAKE_PREFIX_PATH="$PATH_TO_LIBTORCH:$CMAKE_PREFIX_PATH"
ENV PATH="/opt/intel/oneapi/compiler/latest/linux/bin/intel64:/opt/intel/oneapi/compiler/latest/linux/bin:$PATH"
ENV LD_LIBRARY_PATH="$PATH_TO_LIBTORCH/lib:/opt/intel/oneapi/compiler/latest/linux/compiler/lib/intel64_lin:$LD_LIBRARY_PATH"

ENV FC=/opt/intel/oneapi/compiler/2025.3/bin/ifx
ENV CXX=/opt/intel/oneapi/compiler/2025.3/bin/icpx

# 切换回普通用户
USER ${NB_USER}

# 5. 修复权限
RUN chown -R ${NB_USER} ${HOME}

# 3. 克隆代码库
#RUN pwd
RUN git clone https://github.com/wk1984/torchclim.git

# RUN cd torchclim/torch-wrapper
#    && ./env/install-deps.sh
#    && mkdir build \
#    && ./build.sh