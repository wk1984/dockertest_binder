Docker image for DVM-DOS-TEM [v0.8.3]

username: ddt_user

> setup_working_directory.py --input-data-path raw_inputs work
> dvmdostem -l monitor -p 100 -e 100 -s 100 -t 30 -n 0

If you want to run MADS calibration:

> cd mads_calibration
> julia AC-MADS-TEM.jl ca-config-demo.yaml

URL: [mybinder](https://mybinder.org/v2/gh/wk1984/dockertest_binder/HEAD)