FROM wk1984/cryowrf:v1.0

RUN apt-get update && \
    apt-get install python3 python3-pip python3-venv apt-utils libffi -y && \
    pip3 install jupyterlab
    
RUN which jupyter-lab