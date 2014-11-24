#!bin/bash
/usr/bin/mysqld_safe &
sleep 10s
mysql -u root -e "GRANT ALL ON *.* TO 'jbpm'@'localhost' IDENTIFIED BY 'jbpm';"
mysql -u root -e "GRANT ALL ON *.* TO 'jbpm'@'%' IDENTIFIED BY 'jbpm';"
mysql -u root -e "CREATE DATABASE IF NOT EXISTS jbpm"

mysql -u root jbpm < /sql/mysql5-jbpm-schema.sql
mysql -u root jbpm < /sql/quartz_tables_mysql.sql
