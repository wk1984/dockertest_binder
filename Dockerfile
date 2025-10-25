# FROM jupyter/base-notebook:python-3.10.11
FROM mambaorg/micromamba:2.3-cuda12.8.1-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True

USER root

# RUN useradd -m -s /bin/bash jovyan && echo "jovyan:111" | chpasswd
RUN usermod -aG sudo mambauser

RUN apt-get -qq update && apt-get -qq install -y apt-utils xorg git wget build-essential tzdata sudo && \
    apt-get clean && \
    chown -R mambauser:users /home/mambauser && \
    chown -R mambauser:users /usr/local/share/ && \
    rm -rf /var/lib/apt/lists/*

# RUN conda install mamba -y -n base -c conda-forge

RUN micromamba install -c conda-forge -c r -c santandermetgroup --override-channels \
    jupyterlab \
    r-climate4r r-irkernel r-devtools \
	tensorflow-gpu==2.15 tensorflow==2.15 keras=2.15 \
	pycaret==3.* mlflow xgboost catboost && \
    micromamba clean --all --yes 
#	&& R --vanilla -e 'library(devtools);install_github("jasonleebrown/machisplin")'
    
USER mambauser

# ---- 新增的测试步骤 ----
# 在构建时测试 jupyter-lab 是否可以正常调用。
# --version 会打印版本号并成功退出(返回码0)。如果 jupyter-lab 安装失败，构建会在此处停止。
RUN echo "Testing Jupyter Lab installation..." && \
    jupyter-lab --version && \
    echo "Jupyter Lab test successful."

# 验证安装
RUN python -c "import tensorflow as tf; \
               print('TensorFlow version:', tf.__version__); \
			   print('CUDA available:', tf.test.is_built_with_cuda()); \
               print('GPU available:', tf.config.list_physical_devices('GPU'))"

# 设置工作目录
WORKDIR /home/mambauser

CMD ["jupyter-lab",  "--ip=0.0.0.0"  , "--no-browser"]