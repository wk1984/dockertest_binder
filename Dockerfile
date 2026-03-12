FROM centos:centos7.9.2009

WORKDIR /home

RUN wget -q https://github.com/conda-forge/miniforge/releases/download/26.1.0-0/Miniforge3-26.1.0-0-Linux-x86_64.sh