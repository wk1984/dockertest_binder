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
    yum install -y wget curl git cmake3 which sudo \
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
ENV PATH=/opt/julia-1.10.10/bin:${PATH}

RUN . /root/.bashrc \
    && /opt/miniconda3/bin/conda init bash \
    && conda info --envs \
    && conda install jupyterlab -c conda-forge \
    && which jupyter
	
# 创建CONDA环境来安装DL4DS降尺度软件

ARG DL4DS=false

RUN if [ "$DL4DS" = true ]; then \
    echo "install DL4DS ..."; \
    . /root/.bashrc; \ 
    mamba create -n dl4ds_py39_cu11 -c conda-forge python==3.9.* xarray cartopy requests hdf5 h5py netCDF4 scikit-learn cudatoolkit==11.8.* cudnn==8.9.* seaborn dask pandas numpy==1.* -y; \
    conda activate dl4ds_py39_cu11; \
    pip install tensorflow==2.10.* dl4ds climetlab climetlab_maelstrom_downscaling numpy==1.*; \
    python -V; \
    python -c "import tensorflow as tf; print('Built with CUDA:', tf.test.is_built_with_cuda(), 'USE GPU:', tf.config.list_physical_devices('GPU'))"; \
#	python -c "import dl4ds as dds"; \
	fi
	
# 创建CONDA环境来安装deep4downscaling降尺度软件

ARG deep4downscaling=false
   
RUN if [ "$deep4downscaling" = true ]; then \
    echo "install Deep4Downscaling ..."; \
    . /root/.bashrc; \
	mamba create -n deep4ds_py311_cu12 -c conda-forge python==3.11.* pandas==2.0.2 xarray cartopy numpy scipy sympy xskillscore bottleneck pytorch::pytorch>=2.5.0 -y; \
	conda activate deep4ds_py311_cu12; \
	pip install git+https://github.com/wk1984/deep4downscaling.git@pack_codes; \
#	pip install pandas; \
#	git clone -b pack_codes https://github.com/wk1984/deep4downscaling.git; \
#	cd deep4downscaling
# 	pip install https://github.com/wk1984/deep4downscaling/raw/refs/heads/pack_codes/dist/deep4downscaling-2025.11.3-py3-none-any.whl; \
	fi
	
RUN conda clean --all

RUN wget --quiet https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-1.10.10-linux-x86_64.tar.gz \
    && mv julia-1.10.10-linux-x86_64.tar.gz /opt/julia.tar.gz \
    && cd /opt/ \
    && tar -zxf julia.tar.gz
    
RUN useradd -m -s /bin/bash user && echo "user:111" | chpasswd
RUN usermod -aG wheel user

USER user
WORKDIR /work

RUN which julia \
    && julia -e 'ENV["JUPYTER"]="/opt/miniconda3/bin/jupyter"' \
    && julia -e 'using Pkg; Pkg.add("IJulia")' \
    && julia -e 'using Pkg; Pkg.add("CUDA")' \
    && julia -e 'using Pkg; Pkg.add("cuDNN")' \
    && julia -e 'using Pkg; Pkg.add(url="https://github.com/gher-uliege/DINCAE.jl", rev="main")' \
    && julia -e 'using Pkg; Pkg.add(url="https://github.com/gher-uliege/DINCAE_utils.jl", rev="main")

RUN jupyter-lab --version

CMD ["jupyter-lab",  "--ip=0.0.0.0"  , "--no-browser"]