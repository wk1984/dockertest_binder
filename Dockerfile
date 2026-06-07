FROM gcc:10.4

ENV OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
	DEBIAN_FRONTEND=noninteractive \
	DEBCONF_NONINTERACTIVE_SEEN=true

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget nano \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN cd /root \
	&& wget --quiet https://code.wsl.ch/snow-models/alpine3d/-/package_files/340/download -O alpine3d.deb \
	&& dpkg -i alpine3d.deb