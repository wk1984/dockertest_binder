FROM jupyter/base-notebook:python-3.10.11
# FROM mambaorg/micromamba:2.3-cuda12.8.1-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True

USER root

# RUN useradd -m -s /bin/bash jovyan && echo "jovyan:111" | chpasswd
RUN usermod -aG sudo jovyan

RUN apt-get -qq update && apt-get -qq install -y apt-utils xorg git wget build-essential tzdata sudo && \
    apt-get clean && \
    chown -R jovyan:users /home/jovyan && \
    chown -R jovyan:users /usr/local/share/ && \
    rm -rf /var/lib/apt/lists/*

RUN conda install mamba -y -n base -c conda-forge

RUN mamba install -c conda-forge -c r -c santandermetgroup -c nvidia --override-channels \
    cudatoolkit=11.2.* cudnn=8.1.* numpy=1.* -y
	
RUN pip install tensorflow==2.10.*

RUN mamba install -c conda-forge -c r -c santandermetgroup -c nvidia --override-channels \
    r-base r-irkernel r-devtools r-tensorflow r-reticulate r-keras pycaret mlflow xgboost catboost jupyterlab 
   
RUN R -e "library(devtools);devtools::install_git('https://github.com/SantanderMetGroup/transformer.git', upgrade = 'never')"
RUN R -e "library(devtools);devtools::install_git('https://github.com/SantanderMetGroup/loadeR.java.git', upgrade = 'never')"
RUN R -e "library(devtools);devtools::install_git('https://github.com/SantanderMetGroup/loadeR.2nc.git', upgrade = 'never')"
RUN R -e "library(devtools);devtools::install_git('https://github.com/SantanderMetGroup/climate4r.UDG.git', upgrade = 'never')"
RUN R -e "library(devtools);devtools::install_git('https://github.com/SantanderMetGroup/loadeR.git', upgrade = 'never')"
RUN R -e "library(devtools);devtools::install_git('https://github.com/SantanderMetGroup/VALUE.git', upgrade = 'never')"
RUN R -e "library(devtools);devtools::install_git('https://github.com/SantanderMetGroup/downscaleR.git', upgrade = 'never')"
RUN R -e "library(devtools);devtools::install_git('https://github.com/SantanderMetGroup/downscaleR.keras.git', upgrade = 'never')"
RUN R -e "library(devtools);devtools::install_git('https://github.com/SantanderMetGroup/visualizeR.git', upgrade = 'never')"
RUN R -e "library(devtools);devtools::install_git('https://github.com/SantanderMetGroup/climate4R.value.git', upgrade = 'never')"
RUN R -e "library(devtools);devtools::install_git('https://github.com/jasonleebrown/machisplin.git', upgrade = 'never')"

USER jovyan

# ---- 新增的测试步骤 ----
# 在构建时测试 jupyter-lab 是否可以正常调用。
# --version 会打印版本号并成功退出(返回码0)。如果 jupyter-lab 安装失败，构建会在此处停止。
RUN echo "Testing Jupyter Lab installation..." && \
    jupyter-lab --version && \
    echo "Jupyter Lab test successful."

# 验证安装
RUN echo "Testing Tensorflow installation in Python..." && \
    python -c "import tensorflow as tf; \
               print('TensorFlow version:', tf.__version__); \
			   print('CUDA available:', tf.test.is_built_with_cuda()); \
               print('GPU available:', tf.config.list_physical_devices('GPU'))"
			   
RUN echo "Testing Tensorflow installation in R..." && \
    R -e "library(tensorflow);tf$constant('Hello TensorFlow!')"

# 设置工作目录
WORKDIR /home/jovyan

#CMD ["jupyter-lab",  "--ip=0.0.0.0"  , "--no-browser"]