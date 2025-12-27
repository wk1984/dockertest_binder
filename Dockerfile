# 使用 Ubuntu 作为基镜像
FROM ubuntu:20.04
#FROM intel/oneapi-hpckit:2021.4-devel-ubuntu18.04
#FROM intel/oneapi-hpckit:2022.3.1-devel-ubuntu20.04

# 设置环境变量，避免交互式安装时的提示
ENV DEBIAN_FRONTEND=noninteractive

#RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
#RUN echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | tee /etc/apt/sources.list.d/oneAPI.list

# 1. 安装基础依赖
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    software-properties-common \
    build-essential \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
# 2. 添加 Intel GPG 密钥和 APT 源
RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
    | gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
    | tee /etc/apt/sources.list.d/oneAPI.list

# 3. 安装 Intel oneAPI 编译器组件
# intel-oneapi-compiler-dpcpp-cpp: 包含 icx, icpx (C/C++)
# intel-oneapi-compiler-fortran: 包含 ifx, ifort (Fortran)
RUN apt-get update && apt-get install -y \
    intel-oneapi-compiler-dpcpp-cpp \
    intel-oneapi-compiler-fortran \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
# 4. 配置环境变量
# Intel 编译器需要加载特定的环境变量。
# 我们可以通过设置 ENV 来永久生效，或者在启动时 source vars.sh
ENV PATH="/opt/intel/oneapi/compiler/latest/linux/bin/intel64:/opt/intel/oneapi/compiler/latest/linux/bin:$PATH"
ENV LD_LIBRARY_PATH="/opt/intel/oneapi/compiler/latest/linux/compiler/lib/intel64_lin:$LD_LIBRARY_PATH"

# 验证安装
RUN ifort --version

# 设置 LibTorch 环境变量
ENV SCRIPT_DIR=/root/
ENV Torch_DIR=$SCRIPT_DIR/libtorch
ENV PATH_TO_LIBTORCH=$SCRIPT_DIR/libtorch
# ENV LD_LIBRARY_PATH=$PATH_TO_LIBTORCH/lib:$LD_LIBRARY_PATH

# 3. 克隆代码库
#RUN pwd
RUN git clone https://github.com/wk1984/torchclim.git

#RUN cd torchclim/torch-wrapper \
#    && ./env/install-deps.sh
#    && mkdir build \
#    && ./build.sh