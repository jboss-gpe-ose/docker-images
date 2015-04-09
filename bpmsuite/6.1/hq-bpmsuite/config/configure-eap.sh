#!/bin/bash

echo "configure_eap.sh:   JBOSS_HOME = $JBOSS_HOME"

# replace placeholders in cli file
VARS=( HQ_SHARED_JOURNAL_DIR JGROUPS_SHARED_DISCOVERY_DIR)
for i in "${VARS[@]}"
do
    sed -i "s'@@${i}@@'${!i}'" $CONTAINER_CONFIG/configure-hornetq.cli
    sed -i "s'@@${i}@@'${!i}'" $CONTAINER_CONFIG/configure-jgroups.cli
done

# start eap in admin-only mode
$JBOSS_HOME/bin/standalone.sh --server-config=$JBOSS_CONFIG --admin-only &
sleep 15
$JBOSS_HOME/bin/jboss-cli.sh --connect --file=$CONTAINER_CONFIG/configure-hornetq.cli
$JBOSS_HOME/bin/jboss-cli.sh --connect --file=$CONTAINER_CONFIG/configure-jgroups.cli
$JBOSS_HOME/bin/jboss-cli.sh --connect --file=$CONTAINER_CONFIG/create-queues.cli
$JBOSS_HOME/bin/jboss-cli.sh --connect ":shutdown"



