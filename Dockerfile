FROM jupyter/base-notebook:latest

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

USER root
RUN apt-get update && apt-get install -y xorg git wget build-essential tzdata && apt-get clean && \
    chown -R $NB_USER:users /home/$NB_USER/shared && \
    chown -R jovyan:users /home/jovyan

USER jovyan

RUN conda install mamba -y -n base -c conda-forge && \
    # https://github.com/proxystore/taps/issues/151#issuecomment-2340406425 \
    mamba install -y -n base jupyter 'libsqlite<3.46' nbgitpuller jupyterhub-idle-culler jupyterlab-git \
    tensorflow keras

# climate4R + tensorflow for deep learning
COPY c4r-tf.yml c4r-tf.yml
RUN mamba env create -n climate4tf --file c4r-tf.yml && \
    source /opt/conda/bin/activate climate4tf && \
    mamba install -y -c conda-forge -c r -c santandermetgroup jupyter && \
    R --vanilla -e 'IRkernel::installspec(name = "climate4tf", displayname = "climate4R (deep)", user = FALSE)'
