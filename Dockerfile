FROM ubuntu:18.04

RUN apt-get install wget

RUN wget https://git.wsl.ch/snow-models/meteoio/-/archive/MeteoIO-2.11.0/meteoio-MeteoIO-2.11.0.tar.gz