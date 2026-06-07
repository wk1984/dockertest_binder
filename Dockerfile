FROM ubuntu:18.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    openmpi-bin libopenmpi-dev liblapack3 libblas3 wget curl ca-certificates git sqlite3 language-pack-en nano sudo \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
# 重新声明必要的运行时环境变量
# 路径合并配置
ENV PATH=${ATS_DIR}/bin:${AMANZI_TPLS_DIR}/bin:/opt/miniforge/bin:${PATH} \
    PYTHONPATH=${ATS_SRC_DIR}/tools/utils:${AMANZI_SRC_DIR}/tools/amanzi_xml:${AMANZI_TPLS_DIR}/lib/:${AMANZI_TPLS_DIR}/SEACAS/lib:${PYTHONPATH} \
    LD_LIBRARY_PATH=${ATS_DIR}/lib:${AMANZI_TPLS_DIR}/trilinos-15-1-0/lib:${AMANZI_TPLS_DIR}/SEACAS/lib:${AMANZI_TPLS_DIR}/lib:${LD_LIBRARY_PATH}


RUN cd /root \
    && wget --quiet https://git.wsl.ch/snow-models/meteoio/-/archive/MeteoIO-2.11.0/meteoio-MeteoIO-2.11.0.tar.gz -O ~/meteoio.tar.gz \
    && tar -zxvf meteoio.gz \
    && cd meteoio \
    && ls 
    