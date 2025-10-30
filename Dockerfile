# FROM jupyter/base-notebook:python-3.9.13
FROM jupyter/base-notebook:python-3.11.6

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True

USER root

# RUN useradd -m -s /bin/bash jovyan && echo "jovyan:111" | chpasswd
# RUN usermod -aG sudo jovyan

RUN conda install mamba -y -n base -c conda-forge

RUN mamba install -c conda-forge --override-channels -y \
    intake-esm intake requests aiohttp ipywidgets jupyterlab && \
	conda clean --all -y

USER jovyan

RUN python -c "import intake;intake.open_esm_datastore('https://gitlab.dkrz.de/data-infrastructure-services/intake-esm/-/raw/master/esm-collections/cloud-access/dkrz_cmip6_disk.json')"

# 设置工作目录
WORKDIR /home/jovyan/work

#CMD ["jupyter-lab",  "--ip=0.0.0.0"  , "--no-browser"]