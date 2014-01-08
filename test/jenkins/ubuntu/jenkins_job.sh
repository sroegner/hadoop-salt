N=${BUILD_EXECUTOR:-1}
cd $(dirname $0)
WS=$(pwd)
SCHEMA=$(basename $WS)
COMMAND=${1:-RUN}
REMOTE_USER=ec2-user
[ "${SCHEMA}" == ubuntu ] && REMOTE_USER=ubuntu

SALT_CLOUD_KEY_PATH=${SALT_CLOUD_KEY_PATH:-/etc/salt/jenkins-key.pem}
[ ! -f "${SALT_CLOUD_KEY_PATH}" ] && echo "ERROR: cannot open private_key file ${SALT_CLOUD_KEY_PATH}" && exit 3
SALT_CLOUD=${SALT_CLOUD_PATH:-/home/jenkins/virtual/bin/salt-cloud}
SALT_CLOUD_OPTS="--profiles=${WS}/${SCHEMA}.profiles --map=${WS}/${SCHEMA}.map"
SSH_OPTS="-t -t -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oControlPath=none -oPasswordAuthentication=no -oChallengeResponseAuthentication=no -oPubkeyAuthentication=yes -oKbdInteractiveAuthentication=no -i ${SALT_CLOUD_KEY_PATH}"
STATUS=${WS}/status-${N}.yaml

LOG="${WS}/prov-$(date '+%d%m%Y.%H%M%S').log"
rm -vf prov*log

msg() {
  echo "$BUILD_ID [ $(date) ] === ${1}" | tee -a ${LOG}
}

check_status() {
  sudo ${SALT_CLOUD} ${SALT_CLOUD_OPTS} -F --out=yaml 2>/dev/null > ${STATUS}
  python ${WS}/parse.py -f ${STATUS} $1 > /dev/null
  echo $?
}

start_map() {
  sudo ${SALT_CLOUD} ${SALT_CLOUD_OPTS} -y
}

destroy_map() {
  sudo ${SALT_CLOUD} ${SALT_CLOUD_OPTS} -d -y
}


msg "Checking for existing instances"
all_down=$(check_status all_down)

if [ $all_down -ne 0 ]
then
  msg "Hosts in map-${N} are still up - will destroy the map now"
  destroy_map
  all_down_again=$(check_status all_down)
  if [ $all_down_again -ne 0 ]
  then
    msg "Destroy was unsuccessful - exiting ..."
    exit 5
  fi
fi

[ "${COMMAND}" == DESTROY ] && exit 0

msg "Starting map ${MAP} now"
start_map

all_up=127
attempts=0
max_attempts=3

while [ $all_up -eq 127 -a $attempts -le $max_attempts ]
do
  all_up=$(check_status all_up)
  let attempts=$attempts+1
  if [ $attempts -le $max_attempts ]
  then
    msg "Wait for 10 seconds before checking started instances again"
    sleep 10
  fi
done

if [ $all_up -ne 0 ]
then
  msg "Something went wrong - apparently not all machines are up"
  cat $STATUS
  exit 1
fi

# status should be good usable here
MASTER=$(python ${WS}/parse.py -f ${STATUS} master_ip)
SLAVE=$(python ${WS}/parse.py -f ${STATUS} first_slave_ip)
msg "The ip address of the master node appears to be ${MASTER}"
msg "The ip address of the first slave node appears to be ${SLAVE}"

[ "" == "$MASTER" ] && msg "Cannot determine the master IP - giving up" && exit 4 
[ "" == "$SLAVE" ] && msg "Cannot determine the slave IP - giving up" && exit 4 

TEST_PROPERTIES_FILE=${TEST_PROPERTIES_FILE:-${WS}/../ci.properties}
echo "ci.accumulo.master=${MASTER}" > ${TEST_PROPERTIES_FILE}
echo "ci.accumulo.slave=${SLAVE}" >> ${TEST_PROPERTIES_FILE}
echo "" >> ${TEST_PROPERTIES_FILE}

msg "Sleep a moment ..."
sleep 30
msg "Checking a pillar"
sudo ssh $SSH_OPTS ${REMOTE_USER}@${MASTER} 'sudo salt \* pillar.get mvn' 2>&1 | tee -a $LOG
msg "Listing cached remotes - there should be some hashes here:"
sudo ssh $SSH_OPTS ${REMOTE_USER}@${MASTER} 'ls /var/cache/salt/master/gitfs /var/cache/salt/master/pillar*/0'
msg "Provision the cluster now ... this will take a couple minutes"
sudo ssh $SSH_OPTS ${REMOTE_USER}@${MASTER} 'sudo salt \* state.highstate' 

