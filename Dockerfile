FROM jupyter/base-notebook:latest

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

USER root

RUN usermod -aG sudo jovyan

RUN apt-get update && apt-get install -y xorg git wget build-essential tzdata sudo && apt-get clean && \
#     chown -R $NB_USER:users /home/$NB_USER/shared && \
    chown -R jovyan:users /home/jovyan && \
    chown -R jovyan:users /usr/local/share/ && \
    rm -rf /var/lib/apt/lists/*

USER jovyan

RUN conda install mamba -y -n base -c conda-forge

# climate4R + tensorflow for deep learning
COPY c4r-tf.yml c4r-tf.yml
RUN mamba env create -n climate4tf --file c4r-tf.yml && \
    source /opt/conda/bin/activate climate4tf && \
    mamba install -y -c conda-forge -c r -c santandermetgroup jupyter && \
    R --vanilla -e 'IRkernel::installspec(name = "climate4tf", displayname = "climate4R (deep)", user = FALSE)'