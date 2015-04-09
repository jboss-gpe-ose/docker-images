#!/bin/bash

DOCKER_IP=$(ip addr show eth0 | grep -E '^\s*inet' | grep -m1 global | awk '{ print $2 }' | sed 's|/.*||')

echo -en "STARTING HQ CONTAINER\nDOCKER_IP = $DOCKER_IP\n" > $START_LOG_FILE
echo -en "JBOSS_HOME = $JBOSS_HOME\n" >> $START_LOG_FILE
echo -en "JBOSS_CONFIG = $JBOSS_CONFIG\n" >> $START_LOG_FILE
echo -en "HornetQ node = $HORNETQ_NODE\n" >> $START_LOG_FILE
echo -en "HornetQ backup node = $HORNETQ_BACKUP_NODE\n" >> $START_LOG_FILE

JBOSS_COMMON_ARGS="--server-config=$JBOSS_CONFIG -Djboss.bind.address=$DOCKER_IP -Djboss.bind.address.management=$DOCKER_IP -Djboss.bind.address.insecure=$DOCKER_IP -Djboss.node.name=server-$DOCKER_IP"
HORNETQ_ARGS="-Dhornetq.node=$HORNETQ_NODE -Dhornetq.backup.node=$HORNETQ_BACKUP_NODE"

# customize size of JVM heap
JAVA_OPTS="-Xms128m -Xmx512m -Djava.net.preferIPv4Stack=true -Djava.awt.headless=true -Djboss.modules.policy-permissions=true"
export JAVA_OPTS

# start jboss hornetq
nohup $JBOSS_HOME/bin/standalone.sh $JBOSS_COMMON_ARGS $HORNETQ_ARGS >> $START_LOG_FILE 2>&1
