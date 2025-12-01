FROM python:3.11

RUN apt-get install python3-jupyter
	
# 设置环境变量，允许 root 用户运行 MPI
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
ARG DEBIAN_FRONTEND=noninteractive
ENV SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True
    
#=============================================================================================
#  Set up Python Jupyter Environment ...
#=============================================================================================
    
RUN useradd -m -s /bin/bash user && echo "user:111" | chpasswd
RUN usermod -aG sudo user

USER user
WORKDIR /work

RUN jupyter-lab --version

CMD ["jupyter-lab",  "--ip=0.0.0.0"  , "--no-browser"]