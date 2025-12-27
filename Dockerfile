FROM wk1984/dvmdostem:v0.8.3

USER user
WORKDIR /home/user

RUN mkdir example_run

RUN dvmdostem --sha

RUN git clone https://github.com/uaf-arctic-eco-modeling/dvm-dos-tem.git

RUN setup_working_directory.py --input-data-path /home/user/dvm-dos-tem/demo-data/cru-ts40_ar5_rcp85_ncar-ccsm4_toolik_field_station_10x10/ /home/user/example_run