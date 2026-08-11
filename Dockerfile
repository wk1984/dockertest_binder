FROM quay.io/jupyter/r-notebook

ENV DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true

#RUN sed -i "s@http://.*archive.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list \
#    && sed -i "s@http://.*security.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list

USER root

# 安装编译所需的依赖（包含各种 -dev 包和构建工具）
RUN sudo apt-get update && apt-get install -y --no-install-recommends \
    git wget nano gmt ca-certificates

USER jovyan

RUN cd /home/jovyan \
   && git clone https://github.com/PIK-LPJmL/LandInG.git