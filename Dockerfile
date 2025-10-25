FROM jupyter/base-notebook:python-3.9.13

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

USER root

RUN usermod -aG sudo jovyan

RUN apt-get update && apt-get install -y xorg git wget build-essential tzdata sudo && apt-get clean && \
    chown -R jovyan:users /home/jovyan && \
    chown -R jovyan:users /usr/local/share/ && \
    rm -rf /var/lib/apt/lists/*

RUN conda install mamba -y -n base -c conda-forge

RUN mamba install -c conda-forge -c r -c santandermetgroup --override-channels \
  r-base=3.6.* \
  r-loader=1.7.1 \
  r-loader.2nc=0.1.1 \
  r-transformer=2.1.0 \
  r-downscaler=3.3.2 \
  r-visualizer=1.6.0 \
  r-downscaler.keras=1.0.0 \
  r-climate4r.value=0.0.2 \
  r-climate4r.udg=0.2.4 \
  r-value=2.2.2 \
  r-loader.java=1.1.1 \
  r-tensorflow=2.6.0 \
  r-irkernel=1.2 \
  r-magrittr=2.0.1 \
  r-rcolorbrewer=1.1_2 \
  r-gridextra=2.3 \
  r-ggplot2=3.3.3 \
  tensorflow=2.6.* \
  keras=2.6.* \
  jupyter \
  python=3.9.* && \
  mamba clean --all --yes && \
  R --vanilla -e 'IRkernel::installspec(name = "base", displayname = "climate4R (deep)", user = FALSE)'
    
USER jovyan

RUN jupyter-lab --version