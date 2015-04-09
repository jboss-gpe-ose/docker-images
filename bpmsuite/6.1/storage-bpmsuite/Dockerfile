FROM docker-registry.usersys.redhat.com/brew/rhel7:1

# Perform updates
RUN yum -y update && yum clean all

# Create user jboss (with Ids that match that of jboss user created in:  http://git.app.eng.bos.redhat.com/git/jboss-dockerfiles.git at base/rhel7/Dockerfile
RUN groupadd -r jboss -g 185 && useradd -u 185 -r -g jboss -d /opt/jboss -s /bin/bash -c "JBoss user" jboss
RUN mkdir -p /opt/shared/hq-journal
RUN mkdir -p /opt/shared/hq-cluster-discovery
RUN mkdir -p /opt/shared/bpm/artifact-repo
RUN mkdir -p /opt/shared/bpm/git
RUN mkdir -p /opt/shared/bpm/lucene

# Change permissions to user jboss
RUN chown -R jboss:jboss /opt/shared

# Mount as volume
VOLUME /opt/shared/hq-journal
VOLUME /opt/shared/hq-cluster-discovery
VOLUME /opt/shared/bpm/artifact-repo
VOLUME /opt/shared/bpm/git
VOLUME /opt/shared/bpm/lucene

CMD true
