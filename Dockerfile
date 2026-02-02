FROM dvmdostem:v0.8.3

RUN which dvmdostem \
    && dvmdostem --sha
   
USER jovyan

WORKDIR /work

# CMD ["/bin/bash"]