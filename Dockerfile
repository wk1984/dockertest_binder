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
ENV SITE_SPECIFIC_INCLUDES="-I/opt/miniconda3/include/"
ENV LD_LIBRARY_PATH=/opt/miniconda3/lib:$LD_LIBRARY_PATH
ENV PATH="/opt/dvm-dos-tem:$PATH"
ENV PATH="/opt/dvm-dos-tem/scripts:$PATH"
ENV PATH="/opt/dvm-dos-tem/scripts/util:$PATH"

RUN . /root/.bashrc \
    && /opt/miniconda3/bin/conda init bash \
    && conda info --envs \
 	&& mamba install -y ipykernel libzlib libcurl gcc==11.4.0 gxx==11.4.0 gfortran==11.4.0 jsoncpp==1.9.5 boost==1.74.0 libgfortran==3.0.0 lapack openmpi -c conda-forge \
 	&& pip install commentjson lhsmdu bokeh netCDF4 \
    && python -V

RUN which mpic++ && mpicc -v && gcc -v

# 设置编译器环境变量
ENV CC=mpicc
ENV CXX=mpicxx
ENV FC=mpif90
ENV F77=mpif77

# HDF5 和 NetCDF 版本
ENV HDF5_VERSION=1.10.7
ENV NETCDF_C_VERSION=4.4.1.1

# 源码下载链接
ENV HDF5_URL="https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.gz"
ENV NETCDF_C_URL="https://gfd-dennou.org/library/netcdf/unidata-mirror/netcdf-${NETCDF_C_VERSION}.tar.gz"

# 下载、编译并安装并行 NetCDF
RUN wget --no-check-certificate ${HDF5_URL} && \
    tar -xzf hdf5-${HDF5_VERSION}.tar.gz && \
	cd hdf5-${HDF5_VERSION} && \
	./configure --prefix=/opt/miniconda3 --enable-parallel --enable-fortran --enable-shared --enable-hl && \
	make && \
	make install 

RUN wget --no-check-certificate ${NETCDF_C_URL} && \
    tar -xzf netcdf-${NETCDF_C_VERSION}.tar.gz && \
    cd netcdf-${NETCDF_C_VERSION} && \
    CPPFLAGS="-I/opt/miniconda3/include/" \
    LDFLAGS="-L/opt/miniconda3/lib/" \
    ./configure --prefix=/opt/miniconda3 --enable-parallel-tests && \
    make && \
    make install

# 克隆 dvm-dos-tem 仓库，使用 --depth 1 进行浅克隆，减小体积
RUN git clone --depth 1 -b v0.8.3 https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git /opt/dvm-dos-tem

# 编译模型
RUN cd /opt/dvm-dos-tem && . /root/.bashrc && make USEMPI=true CC=mpic++

RUN dvmdostem --help

# RUN useradd -m -s /bin/bash user && echo "user:111" | chpasswd