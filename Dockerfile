FROM jupyterhub/jupyterhub:5.3

RUN apt-get update \
    && apt-get install wget git nano \
    && git clone -b v2.0 https://github.com/environmental-modeling-workflows/watershed-workflow.git