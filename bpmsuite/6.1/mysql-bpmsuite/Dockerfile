FROM rhel7

# Perform updates
RUN yum -y update; yum clean all

# Pull supervisor package from EPEL
RUN rpm -ivh http://mirror.symnds.com/distributions/fedora-epel/7/x86_64/e/epel-release-7-2.noarch.rpm
RUN yum install --enablerepo=rhel-7-server-rpms -y supervisor
RUN rpm -e epel-release

# Install supervisor
RUN yum -y install supervisor; yum clean all

# Create directories for supervisor
RUN mkdir -p /var/run/supervisord

# Install mysql
RUN yum -y install mariadb-server; yum clean all

# Init mysql
RUN mysql_install_db
RUN chown -R mysql:mysql /var/lib/mysql

# Add admin user
RUN /usr/bin/mysqld_safe & \
    sleep 10s &&\
    echo "GRANT ALL ON *.* TO admin@'%' IDENTIFIED BY 'redhat' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql

# Configure supervisor
ADD supervisord.conf /etc/supervisord.conf
ADD start-container.sh /start-container.sh

# MySQL - create jboss user and bpm suite 6.1 schema
ADD ./sql /sql
ADD /create-schema.sh /create-schema.sh
RUN chmod 755 /create-schema.sh

#Expose port 3306
EXPOSE 3306

#Entrypoint
ENTRYPOINT ["/bin/bash", "/start-container.sh"]
