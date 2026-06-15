FROM jupyter/base-notebook:x86_64-python-3.11.6

USER root
RUN apt-get install nano

USER jovyan
RUN pip install spicy-snow