#!/bin/bash

. /opt/hq-bpmsuite/config/environment
. /opt/hq-bpmsuite/config/env.sh

IPADDR=$(ip a s | sed -ne '/127.0.0.1/!{s/^[ \t]*inet[ \t]*\([0-9.]\+\)\/.*$/\1/p}')

echo "IPADDR = $IPADDR"
echo "HornetQ node = $HORNETQ_NODE"
echo "HornetQ backup node = $HORNETQ_BACKUP_NODE"

# Sanity checks
if [ ! -d $SERVER_INSTALL_DIR/$SERVER_NAME ]
then
  echo "EAP not installed at $SERVER_INSTALL_DIR/$SERVER_NAME."
  exit 0
fi

CLEAN=false

for var in $@
do
    case $var in
        --clean)
            CLEAN=true
            ;;
        --admin-only)
            ADMIN_ONLY=--admin-only 
    esac
done

# Clean data, log and temp directories
if [ "$CLEAN" = "true" ] 
then
    rm -rf $SERVER_INSTALL_DIR/$SERVER_NAME/standalone/data $SERVER_INSTALL_DIR/$SERVER_NAME/standalone/log $SERVER_INSTALL_DIR/$SERVER_NAME/standalone/tmp
fi

# ensure all jboss directories are still owned by jboss user
chown -R jboss:jboss $SERVER_INSTALL_DIR/$SERVER_NAME

# switch to jboss user to start JVM
su - jboss <<EOF

# customize size of JVM heap
JAVA_OPTS="-Xms128m -Xmx512m -XX:MaxPermSize=256m -Djava.net.preferIPv4Stack=true -Djboss.modules.system.pkgs=$JBOSS_MODULES_SYSTEM_PKGS -Djava.awt.headless=true -Djboss.modules.policy-permissions=true"
export JAVA_OPTS

# start jboss hornetq
nohup ${SERVER_INSTALL_DIR}/${SERVER_NAME}/bin/standalone.sh -Djboss.bind.address=$IPADDR -Djboss.bind.address.management=$IPADDR -Djboss.bind.address.insecure=$IPADDR -Djboss.node.name=server-$IPADDR -Dhornetq.node=$HORNETQ_NODE -Dhornetq.backup.node=$HORNETQ_BACKUP_NODE --server-config=$JBOSS_CONFIG $ADMIN_ONLY &> /tmp/eap_out.log &
EOF
echo "EAP started"
