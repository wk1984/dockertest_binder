FROM centos:centos7.9.2009

# 设置环境变量，允许 root 用户运行 MPI
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
ENV PATH=/opt/miniconda3/bin:${PATH}
ENV LD_LIBRARY_PATH=/opt/miniconda3/lib:$LD_LIBRARY_PATH

# 导入对应源的GPG密钥
RUN rpm --import https://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

# RUN curl -o  /etc/yum.repos.d/CentOS-Base.repo https://repo.huaweicloud.com/repository/conf/CentOS-7-anon.repo
RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo && \
    yum clean all && \
    yum makecache

# 安装所有依赖（一次性安装，减少层数）
RUN yum update -y && \
    yum install -y epel-release && \
    yum groupinstall -y "Development Tools" && \
    yum install -y \
        wget curl git cmake3 which \
        autoconf automake libtool \
        glibc-common && \
    yum clean all && \
    rm -rf /var/cache/yum
    
#=============================================================================================
#  Set up Python Jupyter Environment ...
#=============================================================================================

RUN wget --quiet https://gh-proxy.com/https://github.com/conda-forge/miniforge/releases/download/26.1.0-0/Miniforge3-26.1.0-0-Linux-x86_64.sh -O ~/miniconda.sh \
    && /bin/bash ~/miniconda.sh -b -p /opt/miniconda3 \
    && rm ~/miniconda.sh \
    && ln -s /opt/miniconda3/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". /opt/miniconda3/etc/profile.d/conda.sh" >> ~/.bashrc

RUN . /root/.bashrc \
    && /opt/miniconda3/bin/conda init bash \
    && conda info --envs \
 	&& mamba install -y gcc==11.4.0 gxx==11.4.0 gfortran==11.4.0 libgfortran==3.0.0 lapack openmpi -c conda-forge \
    && python -V
