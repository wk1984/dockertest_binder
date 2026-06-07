FROM ubuntu:18.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    openmpi-bin libopenmpi-dev liblapack3 libblas3 wget curl ca-certificates git sqlite3 language-pack-en nano sudo \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN wget https://git.wsl.ch/snow-models/meteoio/-/archive/MeteoIO-2.11.0/meteoio-MeteoIO-2.11.0.tar.gz