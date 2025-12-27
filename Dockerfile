FROM wk1984/dvmdostem:v0.8.3

USER user
WORKDIR /home/user

RUN setup_working_directory.py --input-data-path /opt/dvm-dos-tem/demo-data/cru-ts40_ar5_rcp85_ncar-ccsm4_toolik_field_station_10x10/ /home/user