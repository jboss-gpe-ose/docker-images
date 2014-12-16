#FROM docker-registry.usersys.redhat.com/goldmann/jboss-eap:6.3
FROM jboss-eap:6.3

USER root

# Perform updates
RUN yum -y update; yum clean all

# Pull supervisor package from EPEL
RUN rpm -ivh http://mirror.symnds.com/distributions/fedora-epel/7/x86_64/e/epel-release-7-5.noarch.rpm
RUN yum install --enablerepo=rhel-7-server-rpms -y supervisor
RUN rpm -e epel-release

# Install supervisor
RUN yum -y install supervisor; yum clean all

# Create directories for supervisor and configuration
RUN mkdir -p /var/run/supervisord
RUN mkdir -p /opt/hq-bpmsuite/config

# Add scripts
ADD ./configure-eap.sh /opt/hq-bpmsuite/config/configure-eap.sh
ADD ./create-queues.sh /opt/hq-bpmsuite/config/create-queues.sh
ADD ./env.sh /opt/hq-bpmsuite/config/env.sh
ADD ./copy-env.sh /opt/hq-bpmsuite/config/copy-env.sh
ADD ./start-container.sh /opt/hq-bpmsuite/config/start-container.sh
ADD ./start-eap.sh /opt/hq-bpmsuite/config/start-eap.sh
ADD ./stop-eap.sh /opt/hq-bpmsuite/config/stop-eap.sh
ADD ./configure-hornetq.cli /opt/hq-bpmsuite/config/configure-hornetq.cli
ADD ./create-queues.cli /opt/hq-bpmsuite/config/create-queues.cli
ADD ./configure-jgroups.cli /opt/hq-bpmsuite/config/configure-jgroups.cli
ADD ./configure-eap.cli /opt/hq-bpmsuite/config/configure-eap.cli
ADD ./supervisord.conf /etc/supervisord.conf

# Set script permissions
RUN chmod 755 /opt/hq-bpmsuite/config/*

# Configure EAP
RUN /opt/hq-bpmsuite/config/configure-eap.sh

# Create Queues
RUN /opt/hq-bpmsuite/config/create-queues.sh

# Assign a shell to jboss user so as to allow switching to this user
RUN usermod -s /bin/bash jboss

# Expose port 8080,9990,9999,5445,5455
EXPOSE 8080 9990 9999 5445 5455

# Entrypoint
ENTRYPOINT ["/bin/bash", "/opt/hq-bpmsuite/config/start-container.sh"]
