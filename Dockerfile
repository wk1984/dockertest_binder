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
WORKDIR /app
RUN git clone https://github.com/dudek313/torchclim.git

WORKDIR /app/torchclim/torch-wrapper

# 4. 配置编译环境 (覆盖 load-env.sh)
# 这里将编译器指向 GNU 版本的 gcc/gfortran
RUN echo "export CC=gcc" > env/load-env.sh && \
    echo "export CXX=g++" >> env/load-env.sh && \
    echo "export FC=gfortran" >> env/load-env.sh && \
    echo "export TORCH_PATH=/opt/libtorch" >> env/load-env.sh

# 5. [重要] 编译前需要手动或通过 sed 修改模型路径
# 假设你的模型在容器内的 /app/model.pt
RUN sed -i 's|std::string script_path = .*|std::string script_path = "/app/model.pt";|' src/interface/torch-wrap.cpp

# 6. 执行编译脚本
# 注意：项目中的 build.sh 可能需要执行权限
RUN chmod +x build.sh env/*.sh && \
    ./build.sh

# 编译完成后，生成的库文件通常位于 build/src/interface/libtorch-plugin.so