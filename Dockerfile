FROM nvpreddy/rhelubi7:7.9-1445

RUN yum install gcc-c++
RUN gcc -v