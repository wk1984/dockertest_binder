FROM jupyter/base-notebook:x86_64-python-3.11.6

USER root
RUN apt-get update -y --fix-missing \
    && apt-get install -y --no-install-recommends nano

USER jovyan
RUN pip install spicy-snow