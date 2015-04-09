FROM ce-registry.usersys.redhat.com/jboss-eap6/eap:6.4

# Perform updates
RUN yum -y update; yum clean all

ENV CONTAINER_CONFIG /opt/hq-bpmsuite/config
RUN mkdir -p $CONTAINER_CONFIG

# Add scripts
ADD ./config/env.sh $CONTAINER_CONFIG/env.sh
ADD ./config/copy-env.sh $CONTAINER_CONFIG/copy-env.sh
ADD ./config/start-eap.sh $CONTAINER_CONFIG/start-eap.sh
ADD ./config/configure-hornetq.cli $CONTAINER_CONFIG/configure-hornetq.cli
ADD ./config/create-queues.cli $CONTAINER_CONFIG/create-queues.cli
ADD ./config/configure-jgroups.cli $CONTAINER_CONFIG/configure-jgroups.cli
ADD ./config/mgmt-users.properties /opt/jboss/eap/standalone/configuration/mgmt-users.properties

# Set script permissions
RUN chmod 755 $CONTAINER_CONFIG/*

# start eap in admin-only mode
USER jboss
RUN $JBOSS_HOME/bin/standalone.sh --server-config=standalone.xml --admin-only & \
    sleep 15s &&\
    $JBOSS_HOME/bin/jboss-cli.sh --connect --file=$CONTAINER_CONFIG/configure-queues.cli

# Configure EAP
RUN $CONTAINER_CONFIG/configure-eap.sh

# Create Queues
RUN $CONTAINER_CONFIG/create-queues.sh

# Expose port 8080,9990,9999,5445,5455
EXPOSE 8080 9990 9999 5445 5455

# Entrypoint
ENTRYPOINT ["/bin/bash", "$CONTAINER_CONFIG/start-eap.sh"]
