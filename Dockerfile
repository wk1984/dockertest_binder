FROM wk1984/ats_dev:v1.6.0

RUN apt-get update -y \
    && apt-get install sqlite3 language-pack-en -y

# install python pkgs ==========

RUN wget --quiet https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-py311_23.10.0-1-Linux-x86_64.sh -O ~/miniforge.sh \
    && /bin/bash ~/miniforge.sh -b -p /opt/miniforge \
    && rm ~/miniforge.sh \
    && ln -s /opt/miniforge/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". /opt/miniforge/etc/profile.d/conda.sh" >> ~/.bashrc

RUN . /root/.bashrc \
    && /opt/miniforge/bin/conda init bash \
#	&& conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main \
#	&& conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r \
    && conda info --envs \
    && conda install mamba -c conda-forge -y

# configure Python packages ==========
    
RUN mamba install -c conda-forge numpy jupyterlab ipykernel xarray matplotlib seaborn dask netcdf4 "h5py<3.15" pandas openpyxl h5netcdf "hdf5<1.15" descartes \
    geopandas rasterio sqlite rioxarray py3dep pygeohydro s3fs colorama libprotobuf pyogrio "shapely>2" -y \
    && conda clean --all
    
RUN cd ${AMANZI_SRC_DIR}/tools/amanzi_xml && python setup.py install
RUN pip install rosetta-soil==0.1.2
RUN git clone -b v2.0 --depth 1 https://github.com/environmental-modeling-workflows/watershed-workflow /opt/watershed-workflow
RUN git clone -b ats-input-spec-1.6 --depth 1 https://github.com/ecoon/ats_input_spec /opt/ats_input_spec

RUN cd /opt/ats_input_spec && python setup.py install
RUN cd /opt/watershed-workflow && python -m pip install -e .

# configure jupyter notebook ==========

#RUN jupyter-notebook --generate-config
#RUN python -c "from jupyter_server.auth import passwd; print(\"c.ServerApp.password = u'\" +  passwd('123456') + \"'\")" >> /root/.jupyter/jupyter_notebook_config.py

#RUN echo c.ServerApp.allow_origin = \'*\'  >> /root/.jupyter/jupyter_notebook_config.py
#RUN echo c.ServerApp.allow_remote_access = True >> /root/.jupyter/jupyter_notebook_config.py
#RUN echo c.ServerApp.ip = \'*\' >> /root/.jupyter/jupyter_notebook_config.py
#RUN echo c.ServerApp.open_browser = False >> /root/.jupyter/jupyter_notebook_config.py
#RUN echo "c.ServerApp.terminado_settings = { \"shell_command\": [\"/usr/bin/bash\"] }" >> /root/.jupyter/jupyter_notebook_config.py

#CMD ["jupyter-lab" ,  "--ip=0.0.0.0"  , "--no-browser" ,  "--allow-root"]