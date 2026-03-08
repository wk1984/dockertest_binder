FROM wk1984/ats:v1.6.0

USER root
RUN chown -R ats_user /home/ats_user
RUN chmod -R u+rwx /home/ats_user

USER ats_user
WORKDIR /home/ats_user