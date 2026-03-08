# ==========================================
# 第一阶段：构建环境 (Builder)
# ==========================================
#FROM opensciencegrid/osgvo-ubuntu-20.04 AS builder
FROM ubuntu:24.04 AS builder

# ==========================================
# 1. 环境变量声明 (完整保留)
# ==========================================
ENV OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
	DEBIAN_FRONTEND=noninteractive \
	DEBCONF_NONINTERACTIVE_SEEN=true \
    ATS_BASE=/opt/ats \
    ATS_BUILD_TYPE=Release \
    ATS_VERSION=ats-1.6 \
    OPENMPI_DIR=/usr/

ENV AMANZI_TPLS_BUILD_DIR=${ATS_BASE}/amanzi_tpls-build-${ATS_VERSION}-${ATS_BUILD_TYPE} \
    AMANZI_TPLS_DIR=${ATS_BASE}/amanzi_tpls-install-${ATS_VERSION}-${ATS_BUILD_TYPE} \
    AMANZI_SRC_DIR=${ATS_BASE}/repos/amanzi \
    AMANZI_BUILD_DIR=${ATS_BASE}/amanzi-build-${ATS_VERSION}-${ATS_BUILD_TYPE} \
    AMANZI_DIR=${ATS_BASE}/amanzi-install-${ATS_VERSION}-${ATS_BUILD_TYPE}

ENV ATS_SRC_DIR=${AMANZI_SRC_DIR}/src/physics/ats \
    ATS_DIR=${AMANZI_DIR}

# 路径合并配置
ENV PATH=${ATS_DIR}/bin:${AMANZI_TPLS_DIR}/bin:/opt/miniforge/bin:${PATH} \
    PYTHONPATH=${ATS_SRC_DIR}/tools/utils:${AMANZI_SRC_DIR}/tools/amanzi_xml:${AMANZI_TPLS_DIR}/SEACAS/lib:${PYTHONPATH} \
    LD_LIBRARY_PATH=${ATS_DIR}/lib:${AMANZI_TPLS_DIR}/trilinos-15-1-0/lib:${AMANZI_TPLS_DIR}/SEACAS/lib:${AMANZI_TPLS_DIR}/lib:${LD_LIBRARY_PATH}

# ==========================================
# 2. 系统依赖安装 (合并以减少镜像层) 
# ==========================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget make m4 patch build-essential ca-certificates cmake curl nano  \
    openmpi-bin libopenmpi-dev liblapack-dev libblas-dev liblapack3 libblas3 \
    git g++ gcc gfortran libcurl4-openssl-dev openssh-server zlib1g-dev libjpeg-dev \
#    python3 python3-dev python3-numpy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ==========================================
# 3. 源码克隆与 ATS 编译 
# ==========================================
# 使用 --depth 1 减小 git 历史体积，但保留当前完整源码
RUN mkdir -p ${ATS_BASE}/amanzi-tpls/Downloads/ && \
    cd ${ATS_BASE} && \
    git clone -b amanzi-1.6 http://github.com/amanzi/amanzi $AMANZI_SRC_DIR

# install python pkgs ==========

RUN wget --quiet https://github.com/conda-forge/miniforge/releases/download/23.11.0-0/Mambaforge-23.11.0-0-Linux-x86_64.sh -O ~/miniforge.sh \
    && /bin/bash ~/miniforge.sh -b -p /opt/miniforge \
    && rm ~/miniforge.sh \
    && ln -s /opt/miniforge/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". /opt/miniforge/etc/profile.d/conda.sh" >> ~/.bashrc

RUN . /root/.bashrc \
    && /opt/miniforge/bin/conda init bash \
#	&& conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main \
#	&& conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r \
    && conda info --envs
	
RUN python --version

# configure Python packages ==========

RUN mamba install -c conda-forge numpy jupyterlab notebook xarray matplotlib seaborn dask netcdf4 "h5py<3.15" pandas openpyxl h5netcdf hdf5==1.12.1 descartes \
    geopandas rasterio sqlite==3.51 rioxarray py3dep pygeohydro s3fs colorama -y \
    && conda clean --all
	
RUN cd ${AMANZI_SRC_DIR}/tools/amanzi_xml && python setup.py install
RUN pip install rosetta-soil==0.1.2
RUN git clone -b v2.0 --depth 1 https://github.com/environmental-modeling-workflows/watershed-workflow /opt/watershed-workflow
RUN git clone -b ats-input-spec-1.6 --depth 1 https://github.com/ecoon/ats_input_spec /opt/ats_input_spec

RUN cd /opt/ats_input_spec && python setup.py install
RUN cd /opt/watershed-workflow && python -m pip install -e .

# configure jupyter notebook ==========

#RUN jupyter-notebook --generate-config
#RUN python -c "from jupyter_server.auth import passwd; print(\"c.ServerApp.password = u'\" +  passwd('123456') + \"'\")" >> /root/.jupyter/jupyter_notebook_config.py

#RUN echo c.ServerApp.allow_origin = \'*\'  >> /root/.jupyter/jupyter_notebook_config.py
#RUN echo c.ServerApp.allow_remote_access = True >> /root/.jupyter/jupyter_notebook_config.py
#RUN echo c.ServerApp.ip = \'*\' >> /root/.jupyter/jupyter_notebook_config.py
#RUN echo c.ServerApp.open_browser = False >> /root/.jupyter/jupyter_notebook_config.py
#RUN echo "c.ServerApp.terminado_settings = { \"shell_command\": [\"/usr/bin/bash\"] }" >> /root/.jupyter/jupyter_notebook_config.py

#CMD ["jupyter-lab" ,  "--ip=0.0.0.0"  , "--no-browser" ,  "--allow-root"]