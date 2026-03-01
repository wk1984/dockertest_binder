FROM ubuntu:24.04

ENV OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
	DEBIAN_FRONTEND=noninteractive \
	DEBCONF_NONINTERACTIVE_SEEN=true \
    ATS_BASE=/opt/ats \
    ATS_BUILD_TYPE=Release \
    ATS_VERSION=ats-1.5 \
    OPENMPI_DIR=/usr/

ENV AMANZI_TPLS_BUILD_DIR=${ATS_BASE}/amanzi_tpls-build-${ATS_VERSION}-${ATS_BUILD_TYPE} \
    AMANZI_TPLS_DIR=${ATS_BASE}/amanzi_tpls-install-${ATS_VERSION}-${ATS_BUILD_TYPE} \
    AMANZI_SRC_DIR=${ATS_BASE}/repos/amanzi \
    AMANZI_BUILD_DIR=${ATS_BASE}/amanzi-build-${ATS_VERSION}-${ATS_BUILD_TYPE} \
    AMANZI_DIR=${ATS_BASE}/amanzi-install-${ATS_VERSION}-${ATS_BUILD_TYPE}

ENV ATS_SRC_DIR=${AMANZI_SRC_DIR}/src/physics/ats \
    ATS_DIR=${AMANZI_DIR}

# 路径合并配置
ENV PATH=${ATS_DIR}/bin:${AMANZI_TPLS_DIR}/bin:${PATH} \
    PYTHONPATH=${ATS_SRC_DIR}/tools/utils:${AMANZI_SRC_DIR}/tools/amanzi_xml:${AMANZI_TPLS_DIR}/SEACAS/lib:${PYTHONPATH} \
    LD_LIBRARY_PATH=${ATS_DIR}/lib:${AMANZI_TPLS_DIR}/trilinos-15-1-0/lib:${AMANZI_TPLS_DIR}/SEACAS/lib:${AMANZI_TPLS_DIR}/lib:${LD_LIBRARY_PATH}

RUN apt-get update && apt-get install -y \
    wget make m4 patch build-essential cmake curl nano \
    openmpi-bin libopenmpi-dev liblapack-dev libblas-dev liblapack3 libblas3 \
    git g++ gcc gfortran libcurl4-openssl-dev openssh-server zlib1g-dev libjpeg-dev \
    python3-numpy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
	
RUN mkdir -p ${ATS_BASE}/amanzi-tpls/Downloads/ && \
    cd ${ATS_BASE} && \
    git clone -b amanzi-1.5 http://github.com/amanzi/amanzi $AMANZI_SRC_DIR
