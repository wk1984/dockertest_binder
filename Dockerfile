FROM centos:centos7.9.2009

# 导入对应源的GPG密钥
RUN rpm --import https://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

# RUN curl -o  /etc/yum.repos.d/CentOS-Base.repo https://repo.huaweicloud.com/repository/conf/CentOS-7-anon.repo
RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo && \
    yum clean all && \
    yum makecache
	
# 设置环境变量，允许 root 用户运行 MPI
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
ARG DEBIAN_FRONTEND=noninteractive
ENV SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True

# 安装所有依赖（一次性安装，减少层数）
RUN yum update -y && \
    yum install -y wget curl git cmake3 which  \
    yum clean all && \
    rm -rf /var/cache/yum
    
#=============================================================================================
#  Set up Python Jupyter Environment ...
#=============================================================================================

RUN wget --quiet https://github.com/conda-forge/miniforge/releases/download/23.11.0-0/Mambaforge-23.11.0-0-Linux-x86_64.sh -O ~/miniconda.sh \
    && /bin/bash ~/miniconda.sh -b -p /opt/miniconda3 \
    && rm ~/miniconda.sh \
    && ln -s /opt/miniconda3/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". /opt/miniconda3/etc/profile.d/conda.sh" >> ~/.bashrc

ENV PATH=/opt/miniconda3/bin:${PATH}

RUN . /root/.bashrc \
    && /opt/miniconda3/bin/conda init bash \
    && conda info --envs
	
RUN . /root/.bashrc \ 
    && mamba create -n dl4ds_py39_cu11 -c conda-forge python==3.9.* xarray cartopy requests hdf5 h5py netCDF4 scikit-learn cudatoolkit==11.2.* cudnn==8.1.* numpy==1.* -y \
    && conda activate dl4ds_py39_cu11 \
    && pip install tensorflow==2.10.* dl4ds climetlab climetlab_maelstrom_downscaling numpy==1.* \
    && python -V \
    && python -c "import tensorflow as tf; print('Built with CUDA:', tf.test.is_built_with_cuda(), tf.config.list_physical_devices('GPU'))"
    
RUN useradd -m -s /bin/bash user && echo "user:111" | chpasswd

USER user
WORKDIR /work