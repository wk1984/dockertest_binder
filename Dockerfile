#-------------------------------------------------------------------
# 阶段 1: "builder"
#
# 这个阶段安装所有开发工具 (git, build-essential, r-devtools)
# 并编译所有的 R 包。
#-------------------------------------------------------------------
FROM jupyter/base-notebook:python-3.10.11 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True

USER root

# 1.1: 安装系统依赖 (包括构建工具)
RUN apt-get -qq update && apt-get -qq install -y \
        apt-utils \
        xorg \
        git \
        wget \
        build-essential \
        tzdata \
        sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # 设置权限 (在基础镜像中已存在，但明确设置是好习惯)
    mkdir -p /opt/conda/lib/R/library && \
    chown -R jovyan:users /home/jovyan /usr/local/share/ /opt/conda/lib/R/library

# 1.2: 安装 Conda/Mamba/Pip 包 (包括 r-devtools)
RUN conda install mamba -y -n base -c conda-forge && \
    mamba install -c conda-forge -c r -c santandermetgroup -c nvidia --override-channels \
        cudatoolkit=11.2.* cudnn=8.1.* numpy=1.* \
        r-base r-irkernel r-devtools r-tensorflow r-reticulate r-keras r-terra r-raster \
        pycaret mlflow xgboost catboost -y && \
    pip install tensorflow==2.10.* && \
    mamba clean -afy && \
    pip cache purge

# 1.3: 安装所有 R 的 GitHub 包
RUN R -e "library(devtools); \
        devtools::install_git('https://github.com/SantanderMetGroup/transformer.git', upgrade = 'never'); \
        devtools::install_git('https://github.com/SantanderMetGroup/loadeR.java.git', upgrade = 'never'); \
        devtools::install_git('https://github.com/SantanderMetGroup/loadeR.2nc.git', upgrade = 'never'); \
        devtools::install_git('https://github.com/SantanderMetGroup/climate4r.UDG.git', upgrade = 'never'); \
        devtools::install_git('https://github.com/SantanderMetGroup/loadeR.git', upgrade = 'never'); \
        devtools::install_git('https://github.com/SantanderMetGroup/VALUE.git', upgrade = 'never'); \
        devtools::install_git('https://github.com/SantanderMetGroup/downscaleR.git', upgrade = 'never'); \
        devtools::install_git('https://github.com/SantanderMetGroup/downscaleR.keras.git', upgrade = 'never'); \
        devtools::install_git('https://github.com/SantanderMetGroup/visualizeR.git', upgrade = 'never'); \
        devtools::install_git('https://github.com/SantanderMetGroup/climate4R.value.git', upgrade = 'never'); \
        devtools::install_git('https://github.com/SantanderMetGroup/climate4R.datasets.git', upgrade = 'never'); \
        devtools::install_github('jasonleebrown/machisplin', upgrade = 'never');" && \
    # 清理 R 编译缓存
    rm -rf /tmp/R*

# 1.4: 下载工作文件
WORKDIR /home/jovyan/work
RUN wget https://raw.githubusercontent.com/wk1984/dockertest_binder/refs/heads/main/demo_downscaleR_keras.ipynb


#-------------------------------------------------------------------
# 阶段 2: "final"
#
# 这是最终的镜像。我们从干净的基础开始，
# 只安装 *运行时* 依赖, 然后从 "builder" 阶段复制已编译好的库。
#-------------------------------------------------------------------
FROM jupyter/base-notebook:python-3.10.11

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True

USER root

# 2.1: 安装 *仅运行时* 的系统依赖
# 注意: 不再需要 git, build-essential, wget
RUN apt-get -qq update && apt-get -qq install -y \
        xorg \
        sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # 创建 R 库目录并设置权限
    mkdir -p /opt/conda/lib/R/library && \
    chown -R jovyan:users /home/jovyan /usr/local/share/ /opt/conda/lib/R/library

# 2.2: 安装 Conda/Mamba/Pip 运行时包
# 注意: 不再需要 r-devtools
RUN conda install mamba -y -n base -c conda-forge && \
    mamba install -c conda-forge -c r -c santandermetgroup -c nvidia --override-channels \
        cudatoolkit=11.2.* cudnn=8.1.* numpy=1.* \
        r-base r-irkernel r-tensorflow r-reticulate r-keras r-terra r-raster \
        pycaret mlflow xgboost catboost -y && \
    pip install tensorflow==2.10.* && \
    mamba clean -afy && \
    pip cache purge

# 2.3: 【魔法步骤】从 builder 阶段复制已编译好的 R 库
# 这是多阶段构建的核心
COPY --from=builder --chown=jovyan:users /opt/conda/lib/R/library /opt/conda/lib/R/library

# 2.4: 复制工作目录文件
COPY --from=builder --chown=jovyan:users /home/jovyan/work /home/jovyan/work

# 2.5: 创建 .Rprofile
RUN echo "library(reticulate);reticulate::use_condaenv('base');" > "/home/jovyan/.Rprofile" && \
    chown jovyan:users /home/jovyan/.Rprofile

# 切换回 jovyan 用户
USER jovyan

# 2.6: 运行测试
RUN echo "Testing Jupyter Lab installation..." && \
    jupyter-lab --version && \
    echo "Jupyter Lab test successful." && \
    echo "Testing Tensorflow installation in Python..." && \
    python -c "import tensorflow as tf; \
               print('TensorFlow version:', tf.__version__); \
               print('CUDA available:', tf.test.is_built_with_cuda()); \
               print('GPU available:', tf.config.list_physical_devices('GPU'))" && \
    echo "Tensorflow test successful."

# 设置工作目录
WORKDIR /home/jovyan/work

# 默认命令
# CMD ["jupyter-lab",  "--ip=0.0.0.0"  , "--no-browser"]