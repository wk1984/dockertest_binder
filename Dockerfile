FROM richxsl/rhel7:min

# RUN cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup 

RUN yum install -y curl

WORKDIR /home

RUN curl -q https://github.com/conda-forge/miniforge/releases/download/26.1.0-0/Miniforge3-26.1.0-0-Linux-x86_64.sh