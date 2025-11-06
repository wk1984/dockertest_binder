FROM centos:centos7.9.2009

RUN yum install devtoolset
#RUN subscription-manager repos --enable rhel-server-devtools-7-rpms