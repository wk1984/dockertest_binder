FROM ubuntu:18.04

ENV FORCE_UNSAFE_CONFIGURE 1
ENV OMPI_ALLOW_RUN_AS_ROOT 1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM 1

ENV nc_inc /usr/include
ENV nc_lib /usr/lib/x86_64-linux-gnu

ENV PATH /Parallel-SnowModel-1.0/:${PATH}
 
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends cmake nano git wget curl libcurl4-openssl-dev openssh-server ca-certificates \
    && apt-get install -y --no-install-recommends open-coarrays-bin libcoarrays-dev openmpi-bin libopenmpi-dev \
    && apt-get install -y --no-install-recommends libnetcdf-dev libnetcdf-cxx-legacy-dev libnetcdff-dev netcdf-bin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/wk1984/Parallel-SnowModel-1.0.git

RUN cd Parallel-SnowModel-1.0/env \
     && caf -o hello_world hello_world.f90 \
     && caf -o hello_world_nc -I${nc_inc} -L${nc_lib} -lnetcdf hello_world_nc.f90
    
RUN cd Parallel-SnowModel-1.0/code \
     && /bin/bash ./compile_snowmodel.script

#RUN wget --quiet https://github.com/conda-forge/miniforge/releases/download/4.12.0-0/Mambaforge-4.12.0-0-Linux-x86_64.sh -O ~/miniforge.sh \

RUN wget --quiet https://github.com/conda-forge/miniforge/releases/download/23.3.0-0/Mambaforge-23.3.0-0-Linux-x86_64.sh -O ~/miniforge.sh \
    && /bin/bash ~/miniforge.sh -b -p /opt/miniforge \
    && rm ~/miniforge.sh \
    && ln -s /opt/miniforge/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". /opt/miniforge/etc/profile.d/conda.sh" >> ~/.bashrc

ENV PATH /opt/miniforge/bin:${PATH}
ARG PATH /opt/miniforge/bin:${PATH}

RUN . /root/.bashrc \
    && /opt/miniforge/bin/conda init bash \
    && conda info --envs \
    && mamba install -c conda-forge jupyterlab notebook==6.5.4 xarray matplotlib libffi seaborn netcdf4 pandas openpyxl descartes cartopy xgrads rioxarray -y \
#    && mamba install -c conda-forge jupyterlab notebook==6.5.4 xarray matplotlib=3.5 libffi=3.3 seaborn netcdf4 pandas openpyxl descartes cartopy -y \
    && conda clean --all
    
# configure jupyter notebook ==========
    
RUN jupyter-notebook --generate-config
RUN python -c "from notebook.auth import passwd; print(\"c.NotebookApp.password = u'\" +  passwd('123456') + \"'\")" >> /root/.jupyter/jupyter_notebook_config.py

RUN echo c.NotebookApp.allow_origin = \'*\'  >> /root/.jupyter/jupyter_notebook_config.py
RUN echo c.NotebookApp.allow_remote_access = True >> /root/.jupyter/jupyter_notebook_config.py
RUN echo c.NotebookApp.ip = \'*\' >> /root/.jupyter/jupyter_notebook_config.py
RUN echo c.NotebookApp.open_browser = False >> /root/.jupyter/jupyter_notebook_config.py
RUN echo "c.NotebookApp.terminado_settings = { \"shell_command\": [\"/bin/bash\"] }" >> /root/.jupyter/jupyter_notebook_config.py

CMD ["jupyter-lab" ,  "--ip=0.0.0.0"  , "--no-browser" ,  "--allow-root"]