FROM rhel7

# Perform updates
RUN yum -y update; yum clean all

# Install mysql
RUN yum -y install mariadb-server; yum clean all

# Init mysql
RUN mysql_install_db
RUN chown -R mysql:mysql /var/lib/mysql

# MySQL - create jboss user and bpm suite 6.1 schema
ADD ./sql /sql
ADD /create-schema.sh /create-schema.sh

# Add admin user
RUN /usr/bin/mysqld_safe & \
    sleep 10s &&\
    echo "GRANT ALL ON *.* TO admin@'%' IDENTIFIED BY 'redhat' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql -u root\
    echo "GRANT ALL ON *.* TO 'jbpm'@'localhost' IDENTIFIED BY 'jbpm'; FLUSH PRIVILEGES" | mysql -u root\
    echo "GRANT ALL ON *.* TO 'jbpm'@'%' IDENTIFIED BY 'jbpm'; FLUSH PRIVILEGES" | mysql -u root\
    echo "CREATE DATABASE IF NOT EXISTS jbpm" | mysql mysql -u root\
    echo "mysql -u root jbpm < /sql/mysql5-jbpm-schema.sql" \
    echo "mysql -u root jbpm < /sql/quartz_tables_mysql.sql" \

#Expose port 3306
EXPOSE 3306

#Entrypoint
ENTRYPOINT ["/usr/bin/mysqld_safe"]
