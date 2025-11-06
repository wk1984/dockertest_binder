FROM nvpreddy/rhelubi7:7.9-1445

# RUN yum install gcc-c++
RUN subscription-manager repos --enable rhel-server-devtools-7-rpms