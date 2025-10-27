FROM jupyter/base-notebook:python-3.9.13

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True

USER root

# RUN useradd -m -s /bin/bash jovyan && echo "jovyan:111" | chpasswd
RUN usermod -aG sudo jovyan

RUN apt-get -qq update && apt-get -qq install -y git wget build-essential tzdata sudo && \
    apt-get clean && \
    chown -R jovyan:users /home/jovyan && \
    chown -R jovyan:users /usr/local/share/ && \
    rm -rf /var/lib/apt/lists/*

RUN conda install mamba -y -n base -c conda-forge

RUN mamba install -c conda-forge -c r -c santandermetgroup -c nvidia --override-channels \
    cartopy hdf5 h5py netCDF4 scikit-learn \
    cudatoolkit=11.2.* cudnn=8.1.* numpy=1.* -y
	
RUN pip install tensorflow==2.10.* dl4ds climetlab climetlab_maelstrom_downscaling numpy=1.*

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

# 设置工作目录
WORKDIR /home/jovyan/work
RUN wget https://github.com/carlos-gg/dl4ds/blob/master/notebooks/DL4DS_tutorial.ipynb

#CMD ["jupyter-lab",  "--ip=0.0.0.0"  , "--no-browser"]