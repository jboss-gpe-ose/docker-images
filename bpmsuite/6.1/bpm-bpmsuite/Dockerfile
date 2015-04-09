FROM ce-registry.usersys.redhat.com/jboss-eap6/eap:6.4
MAINTAINER "JA Bride"

# Expose CLI as well as BPMS git & ssh ports
EXPOSE 9999 9520 9521

####### RDBMS DRIVERS ############
USER root
RUN yum install -y postgresql-jdbc mysql-connector-java iproute && yum clean all -y

ENV CONTAINER_CONFIG /opt/bpm-bpmsuite/config
ENV START_LOG_FILE=/tmp/start-eap.log

# BPM Suite 6.1 zip file
ENV BPM_ZIP jboss-bpmsuite-6.1.0.GA-deployable-eap6.x.zip
ENV BPM_ZIP_PATH /resources/$BPM_ZIP

# Default values for database connection variables
ENV DEFAULT_DIALECT=org.hibernate.dialect.H2Dialect
ENV DIALECT=org.hibernate.dialect.H2Dialect
ENV BPMS_CONNECTION_URL "jdbc:h2:mem:test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
ENV BPMS_CONNECTION_DRIVER h2
ENV BPMS_CONNECTION_USER sa
ENV BPMS_CONNECTION_PASSWORD sa

# Cluster related envs
# ENV BPMS_CLUSTER_NAME // Not set by default
# ENV BPMS_ZOOKEEPER_SERVER // Not set by default
ENV BPMS_VFS_LOCK bpms-vfs-lock
# ENV BPMS_GIT_HOST // Set by default to the container's ip address
ENV BPMS_GIT_PORT 9520
ENV BPMS_GIT_DIR $CONTAINER_CONFIG/vfs
# ENV BPMS_SSH_HOST // Set by default to the container's ip address
ENV BPMS_SSH_PORT 9521
ENV BPMS_INDEX_DIR $CONTAINER_CONFIG/index
ENV BPMS_QUARTZ_PROPERTIES $CONTAINER_CONFIG/quartz-db.properties
# TODO: Docker best practices - Do not use passwords here
ENV BPMS_CLUSTER_PASSWORD bpmsclustering
ENV BPMS_CLUSTER_NODE 1
ENV HELIX_VERSION 0.6.3
ENV HELIX_HOME /opt/eap/helix

#######  Layer BPM Suite 6 on EAP ####
ADD ./resources /resources
RUN unzip -o $BPM_ZIP_PATH -d $JBOSS_HOME && \
    rm -rf $BPM_ZIP_PATH
RUN mkdir -p $CONTAINER_CONFIG/index $CONTAINER_CONFIG/vfs

ADD ./config $CONTAINER_CONFIG
RUN chown -R jboss:jboss $CONTAINER_CONFIG


####### HELIX ############
RUN curl --silent --output /tmp/helix.tar http://ftp.cixug.es/apache/helix/$HELIX_VERSION/binaries/helix-core-$HELIX_VERSION-pkg.tar; \ 
tar -xvf /tmp/helix.tar -C $JBOSS_HOME; \ 
ln -s  $JBOSS_HOME/helix-core-$HELIX_VERSION $JBOSS_HOME/helix; \
rm /tmp/helix.tar

USER jboss
CMD ["/opt/bpm-bpmsuite/config/start-bpms.sh"]
