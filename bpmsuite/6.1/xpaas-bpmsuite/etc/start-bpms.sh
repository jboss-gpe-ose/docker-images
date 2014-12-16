#!/bin/sh


DOCKER_IP=$(ip addr show eth0 | grep -E '^\s*inet' | grep -m1 global | awk '{ print $2 }' | sed 's|/.*||')

echo -en "DOCKER_IP = $DOCKER_IP\n" > /tmp/start-bpms.log

JBOSS_COMMON_ARGS="-Djboss.bind.address=$DOCKER_IP -Djboss.bind.address.management=$DOCKER_IP "
JBOSS_BPMS_DB_ARGUMENTS=
JBOSS_BPMS_CLUSTER_ARGUMENTS=

# JBoss EAP configuration.
if [[ -z "$JBOSS_BIND_ADDRESS" ]] ; then
    echo "Not custom JBoss Application Server bind address set. Using the current container's IP address '$DOCKER_IP'."
    export JBOSS_BIND_ADDRESS=$DOCKER_IP
fi

# *******************
# BPMS database configuration
echo -en "MYSQL_PORT_3306_TCP_ADDR = $MYSQL_PORT_3306_TCP_ADDR" >> /tmp/start-bpms.log
if [ "x$MYSQL_PORT_3306_TCP_ADDR" != "x" ]; then
    JBOSS_BPMS_DB_ARGUMENTS=" -Djboss.bpms.connection_url=jdbc:mysql://$MYSQL_PORT_3306_TCP_ADDR:3306/jbpm -Djboss.bpms.driver=mysql "
    JBOSS_BPMS_DB_ARGUMENTS="$JBOSS_BPMS_DB_ARGUMENTS -Djboss.bpms.username=jbpm -Djboss.bpms.password=jbpm "
else
    JBOSS_BPMS_DB_ARGUMENTS=" -Djboss.bpms.connection_url=\"$BPMS_CONNECTION_URL\" -Djboss.bpms.driver=\"$BPMS_CONNECTION_DRIVER\" "
    JBOSS_BPMS_DB_ARGUMENTS="$JBOSS_BPMS_DB_ARGUMENTS -Djboss.bpms.username=\"$BPMS_CONNECTION_USER\" -Djboss.bpms.password=\"$BPMS_CONNECTION_PASSWORD\" "
fi
# *******************

# *************************************************
# Webapp persistence descriptor dynamic generation.
# *************************************************
PERSISTENCE_TEMPLATE_PATH=/opt/jboss/eap/standalone/deployments/business-central.war/WEB-INF/classes/META-INF/persistence.xml.template
PERSISTENCE_PATH=/opt/jboss/eap/standalone/deployments/business-central.war/WEB-INF/classes/META-INF/persistence.xml
DEFAULT_DIALECT=org.hibernate.dialect.H2Dialect
DIALECT=org.hibernate.dialect.H2Dialect
# Remove, if existing, the current webapp persistence descriptor.
if [ -f $PERSISTENCE_PATH ]; then
    rm -f $PERSISTENCE_PATH
fi
# Check H2 database.
if [[ $BPMS_CONNECTION_DRIVER == *h2* ]]; 
then
    echo "Using H2 dialect for BPMS webapp"
    DIALECT=org.hibernate.dialect.H2Dialect
fi

# Check MySQL database.
if [[ $BPMS_CONNECTION_DRIVER == *mysql* ]] || [ "x$MYSQL_PORT_3306_TCP_ADDR" != "x" ]; 
then
    echo "Using MySQL dialect for BPMS webapp"
    DIALECT=org.hibernate.dialect.MySQLDialect
fi
# Generate the webapp persistence descriptor using the dialect specified.
sed -e "s;$DEFAULT_DIALECT;$DIALECT;" $PERSISTENCE_TEMPLATE_PATH > $PERSISTENCE_PATH

# *********************************************
# EAP standalone descriptor dynamic generation.
# *********************************************
JBOSS_CLUSTER_PROPERTIES_START="<!--"
JBOSS_CLUSTER_PROPERTIES_END="-->"
if [[ ! -z "$BPMS_CLUSTER_NAME" ]] ; then
    echo "Enabling cluster support for BPMS webapp"
    JBOSS_CLUSTER_PROPERTIES_START=""
    JBOSS_CLUSTER_PROPERTIES_END=""
fi
STANDALONE_TEMPLATE_PATH=/opt/jboss/eap/standalone/configuration/standalone-full-ha.xml.template
STANDALONE_PATH=/opt/jboss/eap/standalone/configuration/standalone-full-ha.xml
# Remove, if existing, the current standalone descriptor.
if [ -f $STANDALONE_PATH ]; then
    rm -f $STANDALONE_PATH
fi
# Generate the standalone descriptor.
sed -e "s;%CLUSTER_PROPERTIES_START%;$JBOSS_CLUSTER_PROPERTIES_START;" -e "s;%CLUSTER_PROPERTIES_END%;$JBOSS_CLUSTER_PROPERTIES_END;" $STANDALONE_TEMPLATE_PATH > $STANDALONE_PATH

# ***************************
# BPMS cluster configuration
# ***************************
if [[ ! -z "$BPMS_CLUSTER_NAME" ]] ; then
    
    if [[ -z "$BPMS_GIT_HOST" ]] ; then
        echo "Assigning GIT host adress using current container's ip address '$DOCKER_IP'"
        export BPMS_GIT_HOST=$DOCKER_IP
    fi
    
    if [[ -z "$BPMS_SSH_HOST" ]] ; then
        echo "Assigning SSH host adress using current container's ip address '$DOCKER_IP'"
        export BPMS_SSH_HOST=$DOCKER_IP                
    fi
    
    JBOSS_BPMS_CLUSTER_ARGUMENTS=" -Djboss.bpms.git.host=$BPMS_GIT_HOST -Djboss.bpms.git.port=$BPMS_GIT_PORT -Djboss.bpms.git.dir=$BPMS_GIT_DIR -Djboss.bpms.ssh.host=$BPMS_SSH_HOST -Djboss.bpms.ssh.port=$BPMS_SSH_PORT "
    JBOSS_BPMS_CLUSTER_ARGUMENTS=" $JBOSS_BPMS_CLUSTER_ARGUMENTS -Djboss.bpms.index.dir=$BPMS_INDEX_DIR -Djboss.bpms.cluster.id=$BPMS_CLUSTER_NAME -Djboss.bpms.cluster.zk=$BPMS_ZOOKEEPER_SERVER -Djboss.bpms.cluster.node=$JBOSS_NODE_NAME"
    JBOSS_BPMS_CLUSTER_ARGUMENTS=" $JBOSS_BPMS_CLUSTER_ARGUMENTS -Djboss.bpms.vfs.lock=$BPMS_VFS_LOCK -Djboss.bpms.quartz.properties=$BPMS_QUARTZ_PROPERTIES -Djboss.messaging.cluster.password=$BPMS_CLUSTER_PASSWORD "

    echo "Configuring HELIX client for BPMS server instance '$JBOSS_NODE_NAME' into cluster '$BPMS_CLUSTER_NAME'"
    
    # Register the node.
    echo "Registering cluster node #$BPMS_CLUSTER_NODE named '$JBOSS_NODE_NAME' into '$BPMS_CLUSTER_NAME'"
    $HELIX_HOME/bin/helix-admin.sh --zkSvr $BPMS_ZOOKEEPER_SERVER --addNode $BPMS_CLUSTER_NAME $JBOSS_NODE_NAME
    
    # Rebalance the cluster resource.
    echo "Rebalacing clustered resource '$BPMS_VFS_LOCK' in cluster '$BPMS_CLUSTER_NAME' using $BPMS_CLUSTER_NODE replicas"
    $HELIX_HOME/bin/helix-admin.sh --zkSvr $BPMS_ZOOKEEPER_SERVER --rebalance $BPMS_CLUSTER_NAME $BPMS_VFS_LOCK $BPMS_CLUSTER_NODE
    
fi

# *******************
# OPTIONAL REMOTE MESSAGING BROKER
echo -en "HQ0_PORT_5445_TCP_ADDR = $HQ0_PORT_5445_TCP_ADDR" >> /tmp/start-bpms.log
if [ "x$HQ0_PORT_5445_TCP_ADDR" != "x" ]; then
    echo -en "\nhq0-bpmsuite container has been linked.  Will use this remote HQ broker\n" >> /tmp/start-bpms.log
    echo -en "\nhornetq.remote.address = $HQ0_PORT_5445_TCP_ADDR ; hornetq.remote.port = $HQ0_PORT_5445_TCP_PORT\n" >> /tmp/start-bpms.log

    # create REMOTE_MESSAGING_ARGUMENTS variable to be passed to jboss eap startup
    REMOTE_MESSAGING_ARGUMENTS="-Dhornetq.remote.address=$HQ0_PORT_5445_TCP_ADDR -Dhornetq.remote.port=$HQ0_PORT_5445_TCP_PORT"

    # start eap in admin-only mode
    /opt/jboss/eap/bin/standalone.sh --server-config=standalone-full-ha.xml --admin-only &
    sleep 15

    # execute the CLI that tunes the messaging subsystem
    /opt/jboss/eap/bin/jboss-cli.sh --connect --file=/opt/jboss/bpms/use_remote_hq_broker.cli >> /tmp/start-bpms.log 2>&1
    /opt/jboss/eap/bin/jboss-cli.sh --connect ":shutdown" >> /tmp/start-bpms.log 2>&1

    # remove orignal config that defines KIE related queues
    rm /opt/jboss/eap/standalone/deployments/business-central.war/WEB-INF/bpms-jms.xml
fi
# *******************


# *******************
# OPTIONAL SHARED VOLUME
sharedDir=/opt/shared/bpm
if [ -d "$sharedDir" ]; then
    echo -en "\n$sharedDir exists.  BPM Suite 6 specific file systems will be written to this shared location\n" >> /tmp/start-bpms.log
    SHARED_BPM_FILESYSTEM_ARGUMENTS="-Dorg.uberfire.nio.git.dir=$sharedDir/git -Dorg.guvnor.m2repo.dir=$sharedDir/artifact-repo -Dorg.uberfire.metadata.index.dir=$sharedDir/lucene"
else
    echo -en "\n$sharedDir does not exist.  BPM Suite 6 specific file systems will be written to defaults as per system properties in standalone-full-ha.xml\n" >> /tmp/start-bpms.log
fi

# *******************



# *******************
# RUNNING BPMS Server
# *******************
# Boot EAP with BPMS in standalone mode by default
# When using CMD environment variables are not expanded,
# so we need to specify the $JBOSS_HOME path
#
# The standalone-secure.sh script is used because it's
# recommended by the installation guide.
#
# TODO: Currently BPMS cannot boot using standalone-secure.sh
# As a workaround we use standalone.sh
echo "Starting JBoss BPMS version $JBOSS_BPMS_VERSION-$JBOSS_BPMS_VERSION_RELEASE in standalone mode"
echo "Using as JBoss EAP arguments: $JBOSS_COMMON_ARGS"
echo "Using as JBoss BPMS connection arguments: $JBOSS_BPMS_DB_ARGUMENTS"
if [[ ! -z "$BPMS_CLUSTER_NAME" ]] ; then
    echo "Using as JBoss BPMS cluster arguments: $JBOSS_BPMS_CLUSTER_ARGUMENTS"
fi
/opt/jboss/eap/bin/standalone.sh --server-config=standalone-full-ha.xml $JBOSS_COMMON_ARGS $JBOSS_BPMS_DB_ARGUMENTS $JBOSS_BPMS_CLUSTER_ARGUMENTS $REMOTE_MESSAGING_ARGUMENTS $SHARED_BPM_FILESYSTEM_ARGUMENTS>> /tmp/start-bpms.log 2>&1
