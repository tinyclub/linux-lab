#!/bin/bash
#
# run-docker-lab.sh -- Run the docker image of the lab
#

TOP_DIR=$(dirname `readlink -f $0`)

IMAGE=$(< $TOP_DIR/lab-name)

LAB_HOST_TOOL=$TOP_DIR/run-local-host.sh
LAB_CAPS=$TOP_DIR/lab-caps
LAB_DEVICES=$TOP_DIR/lab-devices
LAB_LIMITS=$TOP_DIR/lab-limits

lab_name=`basename ${IMAGE}`
local_lab_dir=`dirname $TOP_DIR`
remote_lab_dir=/$lab_name/

LAB_CONTAINER_NAME=$TOP_DIR/.lab_container_name
LAB_CONTAINER_ID=$TOP_DIR/.lab_container_id
LAB_LOCAL_PORT=$TOP_DIR/.lab_local_port
LAB_UNIX_PWD=$TOP_DIR/.lab_unix_pwd
LAB_VNC_PWD=$TOP_DIR/.lab_login_pwd

remote_port=6080

# Check container conflicts
CONTAINER_ID=""
[ -f $LAB_CONTAINER_ID ] && CONTAINER_ID=$(< $LAB_CONTAINER_ID)
if [ -n "$CONTAINER_ID" ]; then
    docker ps -f id=$CONTAINER_ID | grep -v PORTS
    if [ $? -eq 0 ]; then
        echo "LOG: $CONTAINER_ID exist, remove $LAB_CONTAINER_ID before create new."
	exit
    fi
fi

# Generate an unique local port
retry=0
local_port=""

while :;
do
    [ $retry -eq 0 ] && [ -f $LAB_LOCAL_PORT ] && local_port=$(< $LAB_LOCAL_PORT)
    [ -z "$local_port" -o $retry -ne 0 ] && local_port=$((RANDOM/500+6080))

    echo "LOG: new vnc port: $local_port"

    # Make sure it is unique
    ports=`docker ps -a | grep -v PORTS | grep "0.0.0.0:" | sed -e "s/.*0.0.0.0:\([0-9]*\)-.*/\1/g" | tr '\n' ' '`
    [ -n "$ports" ] && echo "LOG: old vnc ports: $ports"

    retry=1
    for port in $ports
    do
	if [ $local_port -eq $port ]; then
		retry=2
		break
	fi
    done

    [ $retry -eq 1 ] && break
    echo "LOG: Retry $retry to get an unique port"
done

# Require to prepare some environment for docker containers in host
[ -f $LAB_HOST_TOOL ] && $LAB_HOST_TOOL

# Run the lab via start a lab container
if [ -f $LAB_CAPS ]; then
  lab_caps=""
  for cap in $(< $LAB_CAPS)
  do
    lab_caps="${lab_caps} --cap-add $cap"
  done
fi

if [ -f $LAB_DEVICES  ]; then
  lab_devices=""
  for dev in $(< $LAB_DEVICES)
  do
    lab_devices="${lab_devices} --device $dev"
  done
fi

[ -f $LAB_LIMITS ] && lab_limits=$(< $LAB_LIMITS)

container_name=${lab_name}-${local_port}

CONTAINER_ID=$(docker run --privileged \
		--name ${container_name} \
                ${lab_caps} \
                ${lab_devices} \
                ${lab_limits} \
                -d -p $local_port:$remote_port \
                -v $local_lab_dir:$remote_lab_dir \
                $IMAGE)

echo "LOG: Wait for lab launching..."
while :;
do
    pwd=`docker logs $CONTAINER_ID 2>/dev/null | grep Password`
    sleep 2
    [ -n "$pwd" ] && break
done

echo "LOG: Container: ${CONTAINER_ID:0:12} / $container_name $pwd"

unix_pwd=`echo $pwd | sed -e "s/.* Password: \([^ ]*\) .*/\1/g"`
vnc_pwd=`echo $pwd | sed -e "s/.* VNC-Password: \(.*\)$/\1/g"`

# Save the lab's information
echo ${CONTAINER_ID:0:12} > $LAB_CONTAINER_ID
echo $container_name > $LAB_CONTAINER_NAME
echo $local_port > $LAB_LOCAL_PORT
echo $unix_pwd > $LAB_UNIX_PWD
echo $vnc_pwd > $LAB_VNC_PWD

# Open the lab
$TOP_DIR/open-docker-lab.sh $1
