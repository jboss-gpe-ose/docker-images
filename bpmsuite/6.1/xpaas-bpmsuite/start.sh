#!/bin/sh

# *******************************
# BPMS docker image start script
# *******************************

# Program arguments
#
# -c | --container-name:    The name for the created container.
#                           If not specified, defaults to "xpaas-bpmsuite"
# -d | --connection-driver: The BPMS database connection driver 
#                           If not specified, defaults to "h2!"
# -url | --connection-url:  The BPMS database connection URL 
#                           If not specified, defaults to "jdbc:h2:mem:test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
# -user | --connection-username:    The BPMS database connection username 
#                                   If not specified, defaults to "sa"
# -password | --connection-password:    The BPMS database connection password 
#                                       If not specified, defaults to "sa"
# -useRemoteHQ :  Will connect to remote HQ broker rather than use embedded HQ
# -h | --help;              Show the script usage
#

CONTAINER_NAME="xpaas-bpmsuite"
IMAGE_NAME="redhat/xpaas-bpmsuite"
IMAGE_TAG="6.1"
CONNECTION_DRIVER=h2
CONNECTION_URL="jdbc:h2:mem:test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
CONNECTION_USERNAME=SA
CONNECTION_PASSWORD=SA


function usage
{
     echo "usage: start.sh [ [-c <container_name> ] ] [-h] [-useRemoteHQ] [-useLinkedMySQL] ]"
}

while [ "$1" != "" ]; do
    case $1 in
        -c | --container-name ) shift
                                CONTAINER_NAME=$1
                                ;;
        -d | --connection-driver )  shift
                                CONNECTION_DRIVER=$1
                                ;;
        -url | --connection-url )  shift
                                CONNECTION_URL=$1
                                ;;
        -user | --connection-username )  shift
                                CONNECTION_USERNAME=$1
                                ;;
        -password | --connection-password )  shift
                                CONNECTION_PASSWORD=$1
                                ;;
        -useRemoteHQ )
                                USE_REMOTE_HQ_BROKERS=TRUE
                                ;;
        -useLinkedMySQL ) 
                                USE_LINKED_MYSQL=TRUE
                                ;;
        -h | --help )           usage
                                exit
                                ;;
	* )			usage
				exit 1
    esac
    shift
done

# Check if container is already started
if [ -f docker.pid ]; then
    echo "Container is already started"
    container_id=$(cat docker.pid)
    echo "Stoping container $container_id..."
    docker stop $container_id
    rm -f docker.pid
fi

# Start the xpaas docker container
echo "Starting $CONTAINER_NAME docker container using:"
echo "** Container name: $CONTAINER_NAME"

dockerrun="run ";

if [ x$USE_REMOTE_HQ_BROKERS == xTRUE ]; then
  echo "** USE_REMOTE_HQ_BROKERS: $USE_REMOTE_HQ_BROKERS"
  dockerrun="$dockerrun --link=hq0-bpmsuite:hq0"
fi

if [ x$USE_LINKED_MYSQL == xTRUE ]; then
  echo "** USE_LINKED_MYSQL: $USE_LINKED_MYSQL"
  dockerrun="$dockerrun --link=mysql-bpmsuite:mysql"
else
  echo "** BPMS connection driver: $CONNECTION_DRIVER"
  echo "** BPMS connection URL: $CONNECTION_URL"
  echo "** BPMS connection username: $CONNECTION_USERNAME"
  echo "** BPMS connection password: $CONNECTION_PASSWORD"
  dockerrun="$dockerrun -e BPMS_CONNECTION_URL=$CONNECTION_URL -e BPMS_CONNECTION_DRIVER=$CONNECTION_DRIVER -e BPMS_CONNECTION_USER=$CONNECTION_USERNAME -e BPMS_CONNECTION_PASSWORD=$CONNECTION_PASSWORD"
fi

dockerrun="$dockerrun -P -d --name $CONTAINER_NAME $IMAGE_NAME:$IMAGE_TAG"
echo "dockerrun = docker $dockerrun"

image_xpaas_bpmsuite=$(docker $dockerrun)
ip_bpmsuite=$(docker inspect $image_xpaas_bpmsuite | grep IPAddress | awk '{print $2}' | tr -d '",')
echo $image_xpaas_bpmsuite > docker.pid
docker_pid=$(docker inspect --format '{{ .State.Pid }}' $CONTAINER_NAME)

# End
echo ""
echo "Server starting in $ip_bpmsuite"
echo "You can access the server root context in http://$ip_bpmsuite:8080"
echo "JBoss BPM Suite is running at http://$ip_bpmsuite:8080/business-central"
echo "Log into your new $CONTAINER_NAME container by executing: nsenter -m -u -n -i -p -t $docker_pid /bin/bash"
echo "Linked containers as follows:"
docker inspect -f "{{ .HostConfig.Links }}" $CONTAINER_NAME
exit 0
