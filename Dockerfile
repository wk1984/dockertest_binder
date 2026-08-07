FROM wk1984/lpjml:v6.1.1_runtime

RUN apt-get update && apt-get install -y --no-install-recommends libnetcdf-dev

RUN lpjml --version