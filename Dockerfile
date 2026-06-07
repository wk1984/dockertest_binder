FROM ubuntu:18.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget make m4 patch build-essential ca-certificates cmake curl nano sqlite3 language-pack-en sudo \
    openmpi-bin libopenmpi-dev liblapack-dev libblas-dev liblapack3 libblas3 \
    git g++ gcc gfortran \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
# 重新声明必要的运行时环境变量
# 路径合并配置
#ENV PATH=/root/meteoio-MeteoIO-2.11.0/bin:${AMANZI_TPLS_DIR}/bin:/opt/miniforge/bin:${PATH} \
#    LD_LIBRARY_PATH=/root/meteoio-MeteoIO-2.11.0/lib:${AMANZI_TPLS_DIR}/SEACAS/lib:${AMANZI_TPLS_DIR}/lib:${LD_LIBRARY_PATH}


RUN cd /root \
    && wget --quiet https://git.wsl.ch/snow-models/meteoio/-/archive/MeteoIO-2.11.0/meteoio-MeteoIO-2.11.0.tar.gz -O meteoio.tar.gz \
    && tar -zxvf meteoio.tar.gz \
    && cd meteoio-MeteoIO-2.11.0 \
    && mkdir build && cd build \
    && cmake .. \
    && make \
    && make install 
    
RUN which meteoio_timeseries
    