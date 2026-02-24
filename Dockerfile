FROM opensciencegrid/osgvo-ubuntu-20.04
#FROM opensciencegrid/osgvo-ubuntu-18.04
#FROM ubuntu:16.04

ENV OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
	DEBIAN_FRONTEND=noninteractive \
	DEBCONF_NONINTERACTIVE_SEEN=true 

ENV OPENMPI_DIR=/usr

ENV TZ=Etc/UTC

ENV ATS_BASE=/opt/ats
ENV ATS_BUILD_TYPE=Release

ENV ATS_SRC_DIR=${ATS_BASE}/repos/ats
ENV ATS_BUILD_DIR=${ATS_BASE}/ats-build-${ATS_BUILD_TYPE}
ENV ATS_DIR=${ATS_BASE}/ats-install-${ATS_BUILD_TYPE}

ENV AMANZI_SRC_DIR=${ATS_BASE}/repos/amanzi
ENV AMANZI_BUILD_DIR=${ATS_BASE}/amanzi-build-${ATS_BUILD_TYPE}
ENV AMANZI_DIR=${ATS_BASE}/amanzi-install-${ATS_BUILD_TYPE}

ENV AMANZI_TPLS_BUILD_DIR=${ATS_BASE}/amanzi_tpls-build-${ATS_BUILD_TYPE}
ENV AMANZI_TPLS_DIR=${ATS_BASE}/amanzi_tpls-install-${ATS_BUILD_TYPE}

ENV PATH=${ATS_DIR}/bin:${AMANZI_TPLS_DIR}/bin:${PATH}
ENV PYTHONPATH=${ATS_SRC_DIR}/tools/utils:${PYTHONPATH}

ENV LD_LIBRARY_PATH=${ATS_DIR}/lib:$LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=${AMANZI_DIR}/lib:$LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=${AMANZI_TPLS_DIR}/trilinos-12-12-1/lib:${AMANZI_TPLS_DIR}/SEACAS/lib:${AMANZI_TPLS_DIR}/lib:${LD_LIBRARY_PATH}

RUN sed -i 's@http://.*archive.ubuntu.com@http://mirrors.aliyun.com/@g' /etc/apt/sources.list
RUN sed -i 's@http://.*security.ubuntu.com@http://mirrors.aliyun.com/@g' /etc/apt/sources.list

RUN apt-get update -y \
    && apt-get install -y openmpi-bin ca-certificates build-essential \
	   libopenmpi-dev liblapack-dev libblas-dev liblapack3 libblas3 \
	   git g++ curl wget libcurl4-openssl-dev jupyter nano gfortran \ 
	   python python-numpy jupyter nano python-is-python2 trilinos-dev trilinos-all-dev
	   
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py \
	&& python get-pip.py \
	&& mkdir -p ${ATS_BASE} \
    && mkdir -p ${ATS_BASE}/amanzi-tpls/Downloads/ \
    && cd ${ATS_BASE}/amanzi-tpls/Downloads/ \
    && wget -q https://raw.githubusercontent.com/wk1984/amanzi-tpls/refs/heads/master/src/silo-4.10.2.tar.gz \
	&& wget -q https://raw.githubusercontent.com/wk1984/amanzi-tpls/refs/heads/master/src/superlu_5.2.1.tar.gz \
    && wget -q https://raw.githubusercontent.com/wk1984/amanzi-tpls/refs/heads/master/src/boost_1_67_0.tar.bz2
	
RUN pip install numpy h5py pandas matplotlib seaborn ipykernel notebook Send2Trash==1.8.3

RUN cd ${ATS_BASE} \
    && git clone --depth 1 -b amanzi-0.88 https://gh-proxy.org/https://github.com/amanzi/amanzi $AMANZI_SRC_DIR \
    && git clone --depth 1 -b ats-0.88 https://gh-proxy.org/https://github.com/amanzi/ats $ATS_SRC_DIR

RUN . ${ATS_SRC_DIR}/amanzi_bootstrap.sh

#RUN . ${ATS_SRC_DIR}/amanzi_bootstrap.sh \
#    && . ${ATS_SRC_DIR}/configure-ats.sh
	
#RUN ats --help
