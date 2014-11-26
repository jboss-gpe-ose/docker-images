#!/bin/bash

. /opt/hq-bpmsuite/config/env.sh

if [ ! -d $SERVER_INSTALL_DIR/$SERVER_NAME ]
then
  echo "EAP not installed."
  exit 0
fi

# replace placeholders in cli file
VARS=( HQ_SHARED_JOURNAL_DIR JGROUPS_SHARED_DISCOVERY_DIR)
for i in "${VARS[@]}"
do
    sed -i "s'@@${i}@@'${!i}'" $CLI_HORNETQ	
    sed -i "s'@@${i}@@'${!i}'" $CLI_JGROUPS	
done

# start eap in admin-only mode
${SERVER_INSTALL_DIR}/${SERVER_NAME}/bin/standalone.sh --server-config=$JBOSS_CONFIG --admin-only &
sleep 15
${SERVER_INSTALL_DIR}/${SERVER_NAME}/bin/jboss-cli.sh --connect --controller=${IP_ADDR} --file=${CLI_EAP}
${SERVER_INSTALL_DIR}/${SERVER_NAME}/bin/jboss-cli.sh --connect --controller=${IP_ADDR} --file=${CLI_HORNETQ}
${SERVER_INSTALL_DIR}/${SERVER_NAME}/bin/jboss-cli.sh --connect --controller=${IP_ADDR} --file=${CLI_JGROUPS}
${SERVER_INSTALL_DIR}/${SERVER_NAME}/bin/jboss-cli.sh --connect --controller=${IP_ADDR} ":shutdown"



