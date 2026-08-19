FROM ubuntu:16.04
	
# 设置环境变量，允许 root 用户运行 MPI
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
ARG DEBIAN_FRONTEND=noninteractive

# 安装所有依赖（一次性安装，减少层数）
RUN apt-get update -y && \
    apt-get install -y wget curl git cdo gmt

RUN cdo --version
RUN gmt --version