FROM docker-registry.usersys.redhat.com/brew/rhel7:1

RUN yum -y update && yum -y install mariadb-server && yum clean all

# Init mysql
RUN mysql_install_db
RUN chown -R mysql:mysql /var/lib/mysql

# Add admin user
RUN /usr/bin/mysqld_safe & \
    sleep 10s &&\
    echo "GRANT ALL ON *.* TO admin@'%' IDENTIFIED BY 'redhat' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql

# MySQL - create jboss user and bpm suite 6.1 schema
ADD ./sql /sql
ADD /create-schema.sh /create-schema.sh
RUN chmod 755 /create-schema.sh

RUN /create-schema.sh

#Expose port 3306
EXPOSE 3306

#Entrypoint
ENTRYPOINT ["/bin/bash", "/usr/bin/mysqld_safe"]
