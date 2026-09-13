FROM quay.io/jupyter/julia-notebook

# install julia pkgs ===========
RUN julia -e 'using Pkg; \
    Pkg.add([ \
        "ClimaLand", \
        "ClimaParams", \
        "ClimaDiagnostics", \
		"ClimaTimeSteppers", \
        "CairoMakie", \
        "ClimaAnalysis", \
        "GeoMakie", \
        "ClimaComms", \
        "ClimaUtilities", \
		"CSV", \
		"ProfileCanvas", \
        "Interpolations", \
        "EnsembleKalmanProcesses", \
        "ClimaCore", \
        "Plots"
    ]); \
    Pkg.precompile(); \
    Pkg.gc()'
	
# Make sure the contents of our repo are in ${HOME}
COPY ./*.ipynb /work/

# use in local machine:
# docker build -t clima .
# docker run -it --name clima --volume=${PWD}:/jovyan:delegated --workdir=/jovyan -p 9881:8888 --restart=no --runtime=runc -t -d clima