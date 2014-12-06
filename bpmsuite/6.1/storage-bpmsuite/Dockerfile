FROM rhel7

# Perform updates
RUN yum -y update; yum clean all

# Create user jboss (with Ids that match that of jboss user created in:  docker-registry.usersys.redhat.com/goldmann/jboss-eap:6.3)
RUN groupadd -r jboss -g 1000 && useradd -u 1000 -r -g jboss -d /opt/jboss -s /bin/bash -c "JBoss user" jboss
RUN mkdir -p /opt/shared/hq-journal
RUN mkdir -p /opt/shared/hq-cluster-discovery
RUN mkdir -p /opt/shared/bpm-artifact-repo

# Change permissions to user jboss
RUN chown -R jboss:jboss /opt/shared

# Mount as volume
VOLUME /opt/shared/hq-journal
VOLUME /opt/shared/hq-cluster-discovery
VOLUME /opt/shared/bpm-artifact-repo

CMD true
