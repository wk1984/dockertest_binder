FROM condaforge/miniforge3:26.1.0-0 As Builder

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    LPJROOT=/root/LPJmL \
	PATH=/root/LPJmL/bin:$PATH
	
# RUN sed -i "s@http://.*.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list
	
RUN apt-get update && apt-get -y install cmake pkg-config build-essential mpich

RUN conda install -y dpcpp_linux-64 impi-devel udunits json-c libnetcdf make  -c https://software.repos.intel.com/python/conda/ -c conda-forge

# compile LPJmL >>>

RUN cd /root \
    && /bin/bash \
    && git clone https://github.com/PIK-LPJmL/LPJmL.git \ 
    && cd LPJmL \
	&& ./configure.sh \
	&& make all \
	&& ldd lpjml | grep -i '/' | awk '{print $3}' | xargs -I '{}' cp '{}' .

# <<<

FROM condaforge/miniforge3:26.1.0-0

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    LPJROOT=/root/LPJmL \
	PATH=/root/LPJmL/bin:$PATH
	
COPY --from=Builder /root/LPJmL /root/LPJmL
	
