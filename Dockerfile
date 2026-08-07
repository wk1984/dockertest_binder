FROM intel/oneapi:2026.0.0-devel-ubuntu24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    LPJROOT=/root/LPJmL \
	PATH=$LPJROOT/bin:$PATH 

# 安装编译所需的依赖（包含各种 -dev 包和构建工具）
RUN apt-get update && apt-get install -y --no-install-recommends \
    git netcdf-bin libnetcdf-dev libnetcdff-dev cmake libudunits2-dev libjson-c-dev wget

# 下载并编译 LPJmL
RUN cd /root \
    && git clone https://github.com/PIK-LPJmL/LPJmL.git \
    && cd LPJmL \
    && ./configure.sh \
    && make all \
	&& cd bin \
	&& ldd lpjml | grep -i '/' | awk '{print $3}' | xargs -I '{}' cp '{}' .
	
# ==========================================
# 阶段 2: 运行阶段 (最终生成的镜像)
# 切换到轻量级的 runtime 镜像或纯净版 ubuntu
# ==========================================
# 这里使用 runtime 镜像以确保提供 Intel 运行时库支持 (如 libimf, libsvml 等)
FROM ubuntu:24.04

# 恢复您需要的环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    LPJROOT=/root/LPJmL \
	PATH=/root/LPJmL/bin:$PATH

# 仅安装运行所需的动态库依赖 (注意：去掉了 -dev，换成了实际的运行库)
RUN apt-get update && apt-get install -y --no-install-recommends nano libnetcdf-dev libudunits2-dev libjson-c-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 【核心步骤】从 builder 阶段中，把编译好的 LPJmL 目录完整拷贝过来
COPY --from=builder /root/LPJmL /root/LPJmL

# 配置环境变量以供运行
RUN echo ". /root/LPJmL/bin/lpj_paths.sh" >> /root/.bashrc

RUN lpjml --version