FROM ubuntu:18.04

ENV FORCE_UNSAFE_CONFIGURE=1
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

ENV nc_inc=/usr/include
ENV nc_lib=/usr/lib/x86_64-linux-gnu

ENV PATH=/Parallel-SnowModel-1.0/:${PATH}
 
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends cmake nano git wget curl libcurl4-openssl-dev openssh-server ca-certificates \
    && apt-get install -y --no-install-recommends open-coarrays-bin libcoarrays-dev openmpi-bin libopenmpi-dev \
    && apt-get install -y --no-install-recommends libnetcdf-dev libnetcdf-cxx-legacy-dev libnetcdff-dev netcdf-bin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/wk1984/Parallel-SnowModel-1.0.git

RUN cd Parallel-SnowModel-1.0/env \
     && caf -o hello_world hello_world.f90 \
     && caf -o hello_world_nc -I${nc_inc} -L${nc_lib} -lnetcdf hello_world_nc.f90
    
RUN cd Parallel-SnowModel-1.0/code \
     && /bin/bash ./compile_snowmodel.script \
     && ls ../