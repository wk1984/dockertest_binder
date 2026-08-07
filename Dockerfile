FROM intel/oneapi:2026.0.0-devel-ubuntu24.04

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
    && make all