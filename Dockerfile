FROM centos:centos7.9.2009

# 导入对应源的GPG密钥
RUN rpm --import https://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

# RUN curl -o /etc/yum.repos.d/CentOS-Base.repo HTTPS://mirrors.aliyun.com/repo/Centos-7.repo

# RUN curl -o  /etc/yum.repos.d/CentOS-Base.repo https://repo.huaweicloud.com/repository/conf/CentOS-7-anon.repo
RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo && \
    yum clean all && \
    yum makecache

# 使用阿里云镜像源
# RUN sed -e "s|^mirrorlist=|#mirrorlist=|g" \
#     -e "s|^#baseurl=http://mirror.centos.org/centos/\$releasever|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/7.9|g" \
#     -e "s|^#baseurl=http://mirror.centos.org/\$contentdir/\$releasever|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/7.9|g" \
#     -i.bak \
#     /etc/yum.repos.d/CentOS-*.repo && \
#     yum makecache

# 安装所有依赖（一次性安装，减少层数）
RUN yum update -y && \
    yum install -y epel-release && \
    yum groupinstall -y "Development Tools" && \
    yum install -y \
        wget curl git cmake3 \
        openmpi-devel openmpi \
        boost-devel jsoncpp-devel \
        hdf5-openmpi-devel netcdf-openmpi-devel \
        lapack-devel lapacke-devel geos-devel \
        autoconf automake libtool \
        glibc-common && \
    yum clean all && \
    rm -rf /var/cache/yum

# 设置环境变量（不使用变量扩展）
ENV PATH=/usr/lib64/openmpi/bin:/usr/bin
ENV LD_LIBRARY_PATH=/usr/lib64/openmpi/lib
ENV CC=mpicc
ENV CXX=mpic++
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
ENV SITE_SPECIFIC_INCLUDES="-I/usr/include/jsoncpp -I/usr/include"
ENV SITE_SPECIFIC_LIBS="-L/usr/lib -L/usr/lib64"
# 设置 Boost 相关环境变量
ENV BOOST_ROOT=/usr
ENV BOOST_INCLUDEDIR=/usr/include
ENV BOOST_LIBRARYDIR=/usr/lib64

# 创建符号链接并更新库缓存
RUN ln -s /usr/bin/cmake3 /usr/bin/cmake && \
    /sbin/ldconfig

# 克隆和编译
RUN git clone --depth 1 -b v0.8.3 \
        https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git \
        /opt/dvm-dos-tem

WORKDIR /opt/dvm-dos-tem
# RUN make USEMPI=true CC=mpic++

WORKDIR /workspace