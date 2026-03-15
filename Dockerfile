FROM wk1984/cryowrf:v1.0

RUN apt-get update && \
    apt-get install jupyterlab
    
RUN which jupyter-lab