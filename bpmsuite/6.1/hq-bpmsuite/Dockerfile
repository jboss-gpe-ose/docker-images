FROM ce-registry.usersys.redhat.com/jboss-eap6/eap:6.4

USER root

# Perform updates
RUN yum -y update && yum install -y iproute && yum clean all -y

ENV CONTAINER_CONFIG /opt/hq-bpmsuite/config
ENV JBOSS_CONFIG standalone-full-ha.xml
ENV HQ_SHARED_JOURNAL_DIR=/opt/shared/hq-journal
ENV JGROUPS_SHARED_DISCOVERY_DIR=/opt/shared/hq-cluster-discovery
ENV START_LOG_FILE=/tmp/start-eap.log

# Expose port 8080,9990,9999,5445,5455
EXPOSE 8080 9990 9999 5445 5455

RUN mkdir -p $CONTAINER_CONFIG

# Add scripts
ADD ./config $CONTAINER_CONFIG

# Configure EAP
RUN $CONTAINER_CONFIG/configure-eap.sh
RUN chown -R jboss:jboss /opt

USER jboss
CMD ["/opt/hq-bpmsuite/config/start-eap.sh"]
