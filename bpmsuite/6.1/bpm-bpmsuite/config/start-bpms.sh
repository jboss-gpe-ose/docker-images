#!/bin/sh

DOCKER_IP=$(ip addr show eth0 | grep -E '^\s*inet' | grep -m1 global | awk '{ print $2 }' | sed 's|/.*||')

echo -en "STARTING HQ CONTAINER\nDOCKER_IP = $DOCKER_IP\n" > $START_LOG_FILE
echo -en "JBOSS_HOME = $JBOSS_HOME\n" >> $START_LOG_FILE
echo -en "JBOSS_CONFIG = $JBOSS_CONFIG\n" >> $START_LOG_FILE


COMMON_ARGS="-Djboss.bind.address=$DOCKER_IP -Djboss.bind.address.management=$DOCKER_IP "
BPMS_DB_ARGS=
BPMS_CLUSTER_ARGS=

# JBoss EAP configuration.
if [[ -z "$JBOSS_BIND_ADDRESS" ]] ; then
    echo -en "\nNot custom JBoss Application Server bind address set. Using the current container's IP address '$DOCKER_IP'.\n" >> $START_LOG_FILE
    export JBOSS_BIND_ADDRESS=$DOCKER_IP
fi

cp $CONTAINER_CONFIG/application-users.properties $JBOSS_HOME/standalone/configuration
cp $CONTAINER_CONFIG/application-roles.properties $JBOSS_HOME/standalone/configuration
cp $CONTAINER_CONFIG/mgmt-users.properties $JBOSS_HOME/standalone/configuration

if [[ -z "$BPMS_GIT_HOST" ]] ; then
    export BPMS_GIT_HOST=$DOCKER_IP
fi
    
if [[ -z "$BPMS_SSH_HOST" ]] ; then
    export BPMS_SSH_HOST=$DOCKER_IP                
fi
BPMS_VCONTROL_ARGS=" -Djboss.bpms.git.host=$BPMS_GIT_HOST -Djboss.bpms.git.port=$BPMS_GIT_PORT -Djboss.bpms.git.dir=$BPMS_GIT_DIR -Djboss.bpms.ssh.host=$BPMS_SSH_HOST -Djboss.bpms.ssh.port=$BPMS_SSH_PORT "
BPMS_MISC_ARGS=" -Djboss.bpms.index.dir=$BPMS_INDEX_DIR -Djboss.bpms.quartz.properties=$BPMS_QUARTZ_PROPERTIES"


# ***************************
# BPMS cluster configuration
# ***************************
if [[ ! -z "$BPMS_CLUSTER_NAME" ]] ; then
    
    BPMS_CLUSTER_ARGS=" -Dorg.uberfire.cluster.id=$BPMS_CLUSTER_NAME -Dorg.uberfire.cluster.zk=$BPMS_ZOOKEEPER_SERVER -Dorg.uberfire.cluster.local.id=$JBOSS_NODE_NAME -Dorg.uberfire.cluster.vfs.lock=$BPMS_VFS_LOCK"

    # Register the node.
    echo "Registering cluster node #$BPMS_CLUSTER_NODE named '$JBOSS_NODE_NAME' into '$BPMS_CLUSTER_NAME'"
    $HELIX_HOME/bin/helix-admin.sh --zkSvr $BPMS_ZOOKEEPER_SERVER --addNode $BPMS_CLUSTER_NAME $JBOSS_NODE_NAME
    
    # Rebalance the cluster resource.
    echo "Rebalacing clustered resource '$BPMS_VFS_LOCK' in cluster '$BPMS_CLUSTER_NAME' using $BPMS_CLUSTER_NODE replicas"
    $HELIX_HOME/bin/helix-admin.sh --zkSvr $BPMS_ZOOKEEPER_SERVER --rebalance $BPMS_CLUSTER_NAME $BPMS_VFS_LOCK $BPMS_CLUSTER_NODE
fi


# *******************
# BPMS database configuration
cp -rn $CONTAINER_CONFIG/modules/* $JBOSS_HOME/modules/system/layers/base
ln -sf -t $JBOSS_HOME/modules/system/layers/base/com/mysql/jdbc/main /usr/share/java/mysql-connector-java.jar
ln -sf -t $JBOSS_HOME/modules/system/layers/base/org/postgresql/jdbc/main /usr/share/java/postgresql-jdbc.jar

echo -en "\nMYSQL_PORT_3306_TCP_ADDR = $MYSQL_PORT_3306_TCP_ADDR" >> $START_LOG_FILE
echo -en "\nPOSTGRESQL_PORT_5432_TCP_ADDR = $POSTGRESQL_PORT_5432_TCP_ADDR" >> $START_LOG_FILE
if [ "x$MYSQL_PORT_3306_TCP_ADDR" != "x" ]; then
    BPMS_DB_ARGS=" -Djboss.bpms.connection_url=jdbc:mysql://$MYSQL_PORT_3306_TCP_ADDR:3306/jbpm -Djboss.bpms.driver=mysql "
    BPMS_DB_ARGS="$BPMS_DB_ARGS -Djboss.bpms.username=jbpm -Djboss.bpms.password=jbpm "
    DIALECT=org.hibernate.dialect.MySQLDialect
elif [ "x$POSTGRESQL_PORT_5432_TCP_ADDR" != "x" ]; then
    BPMS_DB_ARGS=" -Djboss.bpms.connection_url=jdbc:postgresql://$POSTGRESQL_PORT_5432_TCP_ADDR:5432/jbpm -Djboss.bpms.driver=postgresql "
    BPMS_DB_ARGS="$BPMS_DB_ARGS -Djboss.bpms.username=jbpm -Djboss.bpms.password=jbpm "
    DIALECT=org.hibernate.dialect.PostgreSQLDialect
else

    # support for external RDBMSs that are not linked through docker
    BPMS_DB_ARGS=" -Djboss.bpms.connection_url=\"$BPMS_CONNECTION_URL\" -Djboss.bpms.driver=\"$BPMS_CONNECTION_DRIVER\" "
    BPMS_DB_ARGS="$BPMS_DB_ARGS -Djboss.bpms.username=\"$BPMS_CONNECTION_USER\" -Djboss.bpms.password=\"$BPMS_CONNECTION_PASSWORD\" "
    if [[ $BPMS_CONNECTION_DRIVER == *mysql* ]]; then
        DIALECT=org.hibernate.dialect.MySQLDialect
    elif [[ $BPMS_CONNECTION_DRIVER == *postgresql* ]]; then
        DIALECT=org.hibernate.dialect.PostgreSQLDialect
    fi
fi
echo -en "\nDIALECT = $DIALECT" >> $START_LOG_FILE

PERSISTENCE_MODIFIED_PATH=$JBOSS_HOME/standalone/deployments/business-central.war/WEB-INF/classes/META-INF/persistence.xml.mod
PERSISTENCE_PATH=$JBOSS_HOME/standalone/deployments/business-central.war/WEB-INF/classes/META-INF/persistence.xml

# Generate the webapp persistence descriptor using the dialect specified.
sed -e "s;$DEFAULT_DIALECT;$DIALECT;" $PERSISTENCE_PATH > $PERSISTENCE_MODIFIED_PATH
mv $PERSISTENCE_MODIFIED_PATH $PERSISTENCE_PATH
# *******************


# *******************
# OPTIONAL REMOTE MESSAGING BROKER
echo -en "\n\nHQ0_PORT_5445_TCP_ADDR = $HQ0_PORT_5445_TCP_ADDR" >> $START_LOG_FILE
if [ "x$HQ0_PORT_5445_TCP_ADDR" != "x" ]; then
    echo -en "\nhq0-bpmsuite container has been linked.  Will use this remote HQ broker\n" >> $START_LOG_FILE
    echo -en "\nhornetq.remote.address = $HQ0_PORT_5445_TCP_ADDR ; hornetq.remote.port = $HQ0_PORT_5445_TCP_PORT\n" >> $START_LOG_FILE

    # create REMOTE_MESSAGING_ARGUMENTS variable to be passed to jboss eap startup
    REMOTE_MESSAGING_ARGUMENTS="-Dhornetq.remote.address=$HQ0_PORT_5445_TCP_ADDR -Dhornetq.remote.port=$HQ0_PORT_5445_TCP_PORT"

    # start eap in admin-only mode
    $JBOSS_HOME/bin/standalone.sh --server-config=$JBOSS_CONFIG --admin-only &
    sleep 15

    # execute the CLI that tunes the messaging subsystem
    $JBOSS_HOME/bin/jboss-cli.sh --connect --file=$CONTAINER_CONFIG/use_remote_hq_broker.cli >> $START_LOG_FILE 2>&1
    $JBOSS_HOME/bin/jboss-cli.sh --connect ":shutdown" >> $START_LOG_FILE 2>&1

    # remove orignal config that defines KIE related queues
    rm $JBOSS_HOME/standalone/deployments/business-central.war/WEB-INF/bpms-jms.xml
fi
# *******************


# *******************
# OPTIONAL SHARED VOLUME
sharedDir=/opt/shared/bpm
if [ -d "$sharedDir" ]; then
    echo -en "\n$sharedDir exists.  BPM Suite 6 specific file systems will be written to this shared location\n" >> $START_LOG_FILE
    SHARED_FS_ARGS="-Dorg.uberfire.nio.git.dir=$sharedDir/git -Dorg.guvnor.m2repo.dir=$sharedDir/artifact-repo -Dorg.uberfire.metadata.index.dir=$sharedDir/lucene"
else
    echo -en "\n$sharedDir does not exist.  BPM Suite 6 specific file systems will be written to defaults as per system properties in $JBOSS_CONFIG\n" >> $START_LOG_FILE
fi

# *******************


# *******************
# BPM PROFILE
echo -en "\nEXEC_SERVER_PROFILE = $EXEC_SERVER_PROFILE\n\n" >> $START_LOG_FILE
if [ "x$EXEC_SERVER_PROFILE" != "x" ]; then
    cp $JBOSS_HOME/standalone/deployments/business-central.war/WEB-INF/web-exec-server.xml $JBOSS_HOME/standalone/deployments/business-central.war/WEB-INF/web.xml
    BPM_PROFILE_ARGS="-Dorg.kie.active.profile=exec-server"

    # Make sure new kie-exec-server web archive is deployed
    rm -f $JBOSS_HOME/standalone/deployments/kie-execution-server.war.skipdeploy
    touch $JBOSS_HOME/standalone/deployments/kie-execution-server.war.dodeploy
else
    cp $JBOSS_HOME/standalone/deployments/business-central.war/WEB-INF/web-ui-server.xml $JBOSS_HOME/standalone/deployments/business-central.war/WEB-INF/web.xml
    BPM_PROFILE_ARGS="-Dorg.kie.active.profile=ui-server"

    # No need for new kie-exec-server web archive
    rm -f $JBOSS_HOME/standalone/deployments/kie-execution-server.war.dodeploy
    touch $JBOSS_HOME/standalone/deployments/kie-execution-server.war.skipdeploy
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
echo -en "Starting JBoss BPMS version $JBOSS_BPMS_VERSION-$JBOSS_BPMS_VERSION_RELEASE in standalone mode\n" >> $START_LOG_FILE
echo -en "Using as JBoss EAP arguments: $COMMON_ARGS\n" >> $START_LOG_FILE
echo -en "Using as JBoss BPMS connection arguments: $BPMS_DB_ARGS\n" >> $START_LOG_FILE
echo -en "Using as JBoss BPMS vcontrol arguments: $BPMS_VCONTROL_ARGS\n" >> $START_LOG_FILE
echo -en "Using as JBoss BPMS misc arguments: $BPMS_MISC_ARGS\n" >> $START_LOG_FILE
echo -en "Using as JBoss BPMS cluster arguments: $BPMS_CLUSTER_ARGS\n" >> $START_LOG_FILE

# customize size of JVM heap
JAVA_OPTS="-Xms128m -Xmx1303m -XX:MaxPermSize=256m -Djava.net.preferIPv4Stack=true -Djboss.modules.system.pkgs=$JBOSS_MODULES_SYSTEM_PKGS -Djava.awt.headless=true -Djboss.modules.policy-permissions=true"
export JAVA_OPTS
$JBOSS_HOME/bin/standalone.sh --server-config=$JBOSS_CONFIG $COMMON_ARGS $BPMS_DB_ARGS $BPMS_VCONTROL_ARGS $BPMS_MISC_ARGS $BPMS_CLUSTER_ARGS $REMOTE_MESSAGING_ARGUMENTS $SHARED_FS_ARGS $BPM_PROFILE_ARGS >> $START_LOG_FILE 2>&1
