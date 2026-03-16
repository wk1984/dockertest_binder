FROM pshuai/ats_workflow:v1.0

# install zenodo_get
RUN pip3 install zenodo_get

# download data from zenodo. This will download a zip file (e.g., data.zip)
RUN cd /home/jovyan && \
    zenodo_get 10.5281/zenodo.10982774