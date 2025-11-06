FROM centos:centos7.9.2009

# 使用阿里云镜像源
RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo && \
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo && \
    yum makecache

# 设置环境变量
ENV TZ=Etc/UTC
ENV NETCDF=/usr
ENV CC=mpicc
ENV CXX=mpicxx
ENV FC=mpif90
ENV F77=mpif77

# 允许 root 用户运行 MPI
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# 安装基础工具
RUN yum update -y && \
    yum install -y epel-release && \
    sed -i 's|^metalink|#metalink|g' /etc/yum.repos.d/epel.repo && \
    sed -i 's|^#baseurl|baseurl|g' /etc/yum.repos.d/epel.repo && \
    yum groupinstall -y "Development Tools" && \
    yum install -y \
        wget curl git cmake3 gcc gcc-c++ gcc-gfortran \
        openmpi-devel openmpi \
        boost-devel jsoncpp-devel \
        hdf5-openmpi-devel netcdf-openmpi-devel \
        lapack-devel lapacke-devel geos-devel \
        autoconf automake libtool && \
    yum clean all && \
    rm -rf /var/cache/yum