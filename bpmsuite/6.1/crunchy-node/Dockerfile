# Originally created by Crunchy Data Solutions, Inc. 
# https://github.com/crunchyds/openshift-3-postgres-example
#
# Modifications (consisting of seeding postgresql database with jbpm schemas)  made by JA Bride

FROM rhel7
MAINTAINER crunchy

RUN yum -y update; yum clean all

# Install postgresql deps
RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
RUN rpm -Uvh http://yum.postgresql.org/9.3/redhat/rhel-7-x86_64/pgdg-redhat93-9.3-1.noarch.rpm
RUN yum install -y procps-ng postgresql93 postgresql93-contrib postgresql93-server libxslt hostname

#
# set up cluster directory
#
RUN mkdir -p /cluster/bin
RUN mkdir -p /pgdata

# set environment vars
ENV PGROOT /usr/pgsql-9.3
ENV PGDATA /pgdata

# add path settings for postgres user
ADD conf/.bash_profile /var/lib/pgsql/

# add volumes to allow backup of postgres files
#VOLUME ["/pgdata"]

# open up the postgres port
EXPOSE 5432

ADD bin /cluster/bin
ADD conf /cluster/conf
RUN chown -R postgres:postgres /cluster
RUN chown -R postgres:postgres /pgdata
RUN chown -R postgres:postgres /var/lib/pgsql

USER postgres

CMD ["/cluster/bin/start-pg-standalone.sh"]
