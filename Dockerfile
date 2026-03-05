FROM jupyterhub/jupyterhub:5.3

RUN git clone -b v2.0 https://github.com/environmental-modeling-workflows/watershed-workflow.git