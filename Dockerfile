FROM centos:centos7.9.2009

# 使用阿里云镜像源
RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo && \
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo && \
    yum makecache

# 安装所有依赖
RUN yum update -y && \
    yum install -y epel-release && \
    sed -i 's|^metalink|#metalink|g' /etc/yum.repos.d/epel.repo && \
    sed -i 's|^#baseurl|baseurl|g' /etc/yum.repos.d/epel.repo && \
    yum groupinstall -y "Development Tools" && \
    yum install -y \
        wget curl git cmake3 \
        openmpi-devel openmpi \
        boost-devel jsoncpp-devel \
        hdf5-openmpi-devel netcdf-openmpi-devel \
        lapack-devel lapacke-devel geos-devel \
        autoconf automake libtool && \
    yum clean all && \
    rm -rf /var/cache/yum

# 设置环境变量（不使用变量扩展）
ENV PATH=/usr/lib64/openmpi/bin:/usr/bin
ENV LD_LIBRARY_PATH=/usr/lib64/openmpi/lib
ENV CC=mpicc
ENV CXX=mpic++
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# 创建符号链接
RUN ln -s /usr/bin/cmake3 /usr/bin/cmake && \
    ldconfig

# 克隆和编译
RUN git clone --depth 1 -b v0.8.3 \
        https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git \
        /opt/dvm-dos-tem

WORKDIR /opt/dvm-dos-tem
RUN make USEMPI=true CC=mpic++

WORKDIR /workspace