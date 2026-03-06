#FROM ubuntu:22.04
FROM pshuai/ats_workflow:v1.5

# ENV PATH=/opt/miniforge/bin:${PATH}

RUN apt-get update -y \
    && apt-get install wget git nano -y \
    && cd /root/ \
	&& git clone -b v2.0 https://github.com/environmental-modeling-workflows/watershed-workflow.git
	
# configure jupyter notebook ==========

RUN conda install -c conda-forge -y numpy matplotlib scipy sqlite geopandas xarray dask rioxarray requests sortedcontainers attrs h5py cftime nc-time-axis pytest mypy nbmake ipympl ipython ipykernel pynhd "pygeohydro>0.18" py3dep s3fs zarr jupyterlab jupyterlab_widgets "notebook<7.0.0" nb_conda nb_conda_kernels papermill gitpython pandas netCDF4 \
     && conda clean --all
     
USER ww

#RUN which python
	
#RUN cd /root/watershed-workflow \
#    && . /root/.bashrc \
#	&& python3.10 -m pip install -e . \
#	&& python3.10 -c "import watershed_workflow" 
	
RUN jupyter-notebook --generate-config
RUN python -c "from jupyter_server.auth import passwd; print(\"c.ServerApp.password = u'\" +  passwd('123456') + \"'\")" >> /root/.jupyter/jupyter_notebook_config.py

RUN echo c.ServerApp.allow_origin = \'*\'  >> /root/.jupyter/jupyter_notebook_config.py
RUN echo c.ServerApp.allow_remote_access = True >> /root/.jupyter/jupyter_notebook_config.py
RUN echo c.ServerApp.ip = \'*\' >> /root/.jupyter/jupyter_notebook_config.py
RUN echo c.ServerApp.open_browser = False >> /root/.jupyter/jupyter_notebook_config.py
RUN echo "c.ServerApp.terminado_settings = { \"shell_command\": [\"/usr/bin/bash\"] }" >> /root/.jupyter/jupyter_notebook_config.py

CMD ["jupyter-lab" ,  "--ip=0.0.0.0"  , "--no-browser" ,  "--allow-root"]