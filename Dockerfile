FROM centos:centos7.9.2009

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

RUN wget --quiet https://github.com/conda-forge/miniforge/releases/download/23.11.0-0/Mambaforge-23.11.0-0-Linux-x86_64.sh -O ~/miniconda.sh \
    && /bin/bash ~/miniconda.sh -b -p /opt/miniconda3 \
    && rm ~/miniconda.sh \
    && ln -s /opt/miniconda3/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". /opt/miniconda3/etc/profile.d/conda.sh" >> ~/.bashrc

ENV PATH=/opt/miniconda3/bin:${PATH}

RUN . /root/.bashrc \
    && /opt/miniconda3/bin/conda init bash \
    && conda info --envs \
    && mamba install -y ipykernel hdf5=*=*openmpi* netcdf4=*=*openmpi* gcc==9.5.* gxx==9.5.* jsoncpp boost -c conda-forge \
    && python -V

RUN which mpic++ && mpicc -v && gcc -v

# 克隆 dvm-dos-tem 仓库，使用 --depth 1 进行浅克隆，减小体积
RUN git clone --depth 1 -b v0.8.3 https://gh-proxy.com/https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git /opt/dvm-dos-tem

# 编译模型
RUN cd /opt/dvm-dos-tem && . /root/.bashrc && make

RUN useradd -m -s /bin/bash user && echo "user:111" | chpasswd

USER user
WORKDIR /work