FROM centos:centos7.9.2009

# 修复 CentOS 7 的 yum 源问题
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo && \
    sed -i 's|#baseurl=http://mirror.centos.org/centos|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo

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

# 安装所有依赖（使用 CentOS 7 默认版本）
RUN yum update -y && \
    yum install -y epel-release && \
    yum groupinstall -y "Development Tools" && \
    yum install -y \
        wget \
        curl \
        git \
        cmake \
        doxygen \
        graphviz \
        gdb \
        gdbserver \
        nano \
        openssl-devel \
        bzip2-devel \
        xz-devel \
        libffi-devel \
        sqlite-devel \
        tk-devel \
        zlib-devel \
        readline-devel \
        ncurses-devel \
        geos-devel \
        lapack-devel \
        lapacke-devel \
        boost-devel \
        jsoncpp-devel \
        openmpi-devel \
        hdf5-openmpi-devel \
        netcdf-openmpi-devel \
        time && \
    yum clean all && \
    rm -rf /var/cache/yum

# 更新动态库
RUN ldconfig

# 克隆 dvm-dos-tem 仓库
RUN git clone --depth 1 -b v0.8.3 \
        https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git \
        /opt/dvm-dos-tem

# 编译模型
WORKDIR /opt/dvm-dos-tem
RUN make USEMPI=true CC=mpicxx

# 设置工作目录
WORKDIR /workspace

# 验证安装
RUN echo "验证安装:" && \
    which mpicc && \
    which mpicxx && \
    mpicxx --version