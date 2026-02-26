FROM opensciencegrid/osgvo-ubuntu-20.04

ENV OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
	DEBIAN_FRONTEND=noninteractive \
	DEBCONF_NONINTERACTIVE_SEEN=true \
	OPENMPI_DIR=/usr/

ENV ATS_BASE=/opt/ats \
    ATS_BUILD_TYPE=Release \
    ATS_VERSION=ats-1.2

ENV AMANZI_TPLS_BUILD_DIR=${ATS_BASE}/amanzi_tpls-build-${ATS_VERSION}-${ATS_BUILD_TYPE} \
    AMANZI_TPLS_DIR=${ATS_BASE}/amanzi_tpls-install-${ATS_VERSION}-${ATS_BUILD_TYPE} \ 
	AMANZI_SRC_DIR=${ATS_BASE}/repos/amanzi \
    AMANZI_BUILD_DIR=${ATS_BASE}/amanzi-build-${ATS_VERSION}-${ATS_BUILD_TYPE} \
	AMANZI_DIR=${ATS_BASE}/amanzi-install-${ATS_VERSION}-${ATS_BUILD_TYPE} \
	ATS_SRC_DIR=${AMANZI_SRC_DIR}/src/physics/ats \
	ATS_DIR=${AMANZI_DIR}
	
ENV PATH=${ATS_DIR}/bin:${AMANZI_TPLS_DIR}/bin:${PATH}
ENV PYTHONPATH=${ATS_SRC_DIR}/tools/utils:${AMANZI_TPLS_DIR}/SEACAS/lib:${AMANZI_SRC_DIR}/tools/amanzi_xml:${PYTHONPATH}
ENV LD_LIBRARY_PATH ${ATS_DIR}/lib:${AMANZI_TPLS_DIR}/trilinos-13-0-afc4e525/lib:${AMANZI_TPLS_DIR}/SEACAS/lib:${AMANZI_TPLS_DIR}/lib:${LD_LIBRARY_PATH}

RUN sed -i 's@http://.*archive.ubuntu.com@https://mirrors.aliyun.com/@g' /etc/apt/sources.list
RUN sed -i 's@http://.*security.ubuntu.com@https://mirrors.aliyun.com/@g' /etc/apt/sources.list

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends wget make m4 patch build-essential ca-certificates cmake openmpi-bin libopenmpi-dev \
	   liblapack-dev libblas-dev liblapack3 libblas3 git g++ gcc gfortran curl libcurl4-openssl-dev \
	   nano openssh-server zlib1g-dev libjpeg-dev \
#    && apt-get install -y --no-install-recommends python3 python3-dev python3-numpy \
#     && apt-get install -y --no-install-recommends python3-setuptools python3-setuptools-scm python3-cffi python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    
# RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

RUN mkdir -p ${ATS_BASE} \
    && mkdir -p ${ATS_BASE}/amanzi-tpls/Downloads/ \
    && cd ${ATS_BASE} \
    && git clone -b amanzi-1.2 http://github.com/amanzi/amanzi $AMANZI_SRC_DIR \
	&& cd ${ATS_BASE}/amanzi-tpls/Downloads/ \
    && wget -q https://raw.githubusercontent.com/wk1984/amanzi-tpls/refs/heads/master/src/silo-4.10.2.tgz \
    && wget -q https://raw.githubusercontent.com/wk1984/amanzi-tpls/refs/heads/master/src/boost_1_67_0.tar.bz2

RUN . ${AMANZI_SRC_DIR}/build_ATS_generic.sh