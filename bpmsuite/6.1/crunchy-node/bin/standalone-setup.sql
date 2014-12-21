
create user jbpm login superuser password 'jbpm';

create database jbpm;

grant all privileges on database jbpm to jbpm;

\c jbpm;

create extension adminpack;

