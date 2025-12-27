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
    wget git unzip \
    gnupg \
    software-properties-common \
    build-essential \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
# 2. 添加 Intel GPG 密钥和 APT 源
RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
    | gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
    | tee /etc/apt/sources.list.d/oneAPI.list \
    && apt-get update && apt-get install -y \
    intel-oneapi-compiler-dpcpp-cpp \
    intel-oneapi-compiler-fortran \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
# 3. 设置 Intel 环境变量 (非常重要！)
# 在 Binder 中，通过 ENV 设置环境变量比 source vars.sh 更可靠
ENV PATH="/opt/intel/oneapi/compiler/latest/linux/bin/intel64:/opt/intel/oneapi/compiler/latest/linux/bin:$PATH"
ENV LD_LIBRARY_PATH="/opt/intel/oneapi/compiler/latest/linux/compiler/lib/intel64_lin:$LD_LIBRARY_PATH"

# 4. 修复权限（Binder 要求 ${HOME} 目录对用户可见且可写）
# ${NB_USER} 是 jupyter 镜像定义的变量，默认为 jovyan
COPY . ${HOME}
RUN chown -R ${NB_USER} ${HOME}

# 切换回普通用户
USER ${NB_USER}

# 验证安装
# RUN which ifort

# 设置 LibTorch 环境变量
ENV SCRIPT_DIR=/home/jovyan/torchclim/torch-wrapper/env
ENV Torch_DIR=$SCRIPT_DIR/libtorch
ENV PATH_TO_LIBTORCH=$SCRIPT_DIR/libtorch
# ENV LD_LIBRARY_PATH=$PATH_TO_LIBTORCH/lib:$LD_LIBRARY_PATH

# 3. 克隆代码库
#RUN pwd
RUN git clone https://github.com/wk1984/torchclim.git

RUN cd torchclim/torch-wrapper \
    && ./env/install-deps.sh
#    && mkdir build \
#    && ./build.sh