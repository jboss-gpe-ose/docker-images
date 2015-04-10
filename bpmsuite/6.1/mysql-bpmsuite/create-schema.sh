#!bin/bash

# dashbuilder appears to make queries that specify lowercase tablenames
# will now make mysql case insensitive
awk '/\[mysqld\]/{print;print "lower_case_table_names=1";next}1' /etc/my.cnf > /etc/my.cnf.new
mv /etc/my.cnf.new /etc/my.cnf

/usr/bin/mysqld_safe &
sleep 10s
mysql -u root -e "GRANT ALL ON *.* TO 'jbpm'@'localhost' IDENTIFIED BY 'jbpm';"
mysql -u root -e "GRANT ALL ON *.* TO 'jbpm'@'%' IDENTIFIED BY 'jbpm';"
mysql -u root -e "CREATE DATABASE IF NOT EXISTS jbpm"

mysql -u root -e "GRANT ALL ON *.* TO 'dashbuilder'@'localhost' IDENTIFIED BY 'dashbuilder';"
mysql -u root -e "GRANT ALL ON *.* TO 'dashbuilder'@'%' IDENTIFIED BY 'dashbuilder';"
mysql -u root -e "CREATE DATABASE IF NOT EXISTS dashbuilder"

mysql -u root jbpm < /sql/mysql5-jbpm-schema.sql
mysql -u root jbpm < /sql/quartz_tables_mysql.sql

# TO-DO:  use dashbuilder database
mysql -u root jbpm < /sql/mysql5-dashbuilder-schema.sql
