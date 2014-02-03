#/bin/bash

cd `dirname $0`

DIR="$( cd "$( dirname "$0" )" && pwd )"
APPS=${APPS:-/data/apps}
PUBLIC_IP=`ifconfig eth0|grep 'inet addr:'| cut -d: -f2 | awk '{ print $1}'`

killz(){
  echo "Killing all docker containers:"
  ids=`docker ps | tail -n +2 |cut -d ' ' -f 1`
  echo $ids | xargs docker kill
  echo $ids | xargs docker rm
}

stop(){
  echo "Stopping all docker containers:"
  ids=`docker ps | tail -n +2 |cut -d ' ' -f 1`
  echo $ids | xargs docker stop
  echo $ids | xargs docker rm
}

init() {
  sudo mkdir -p $APPS
  sudo chown vagrant:vagrant $APPS

  sudo service docker stop
  sudo cp /vagrant/vagrant/etc/default/docker /etc/default/docker
  sleep 1
  sudo service docker start

  if [ ! -f /usr/local/bin/shipyard-agent ] ; then
    sudo wget https://github.com/shipyard/shipyard-agent/releases/download/v0.0.8/shipyard-agent -O /usr/local/bin/shipyard-agent
    sudo chmod +x /usr/local/bin/shipyard-agent
    #apikey=`shipyard-agent -url "http://127.0.0.1:8005" -register|awk '{print $5}'`
    #shipyard-agent -url "http://127.0.0.1:8005" -key $apikey &
  fi

  _update_local_images
}

_start_registry() {
  REGISTRY=$(docker run \
    -name internal_registry \
    -p 5000:5000 \
    -d \
    samalba/docker-registry
  )
  echo "Started REGISTRY in container $REGISTRY"
}

_start_shipyard() {
  SHIPYARD=$(docker run \
    -name shipyard \
    -p 8005:8000 \
    -d \
    shipyard/shipyard
  )
  echo "Started SHIPYARD in container $SHIPYARD"
}

_start_etcd() {
  ETCD1=$(docker run \
    -name etcd-node1 \
    -d \
    -p 4001:4001 \
    -p 8001:8001 \
    coreos/etcd \
    -peer-addr ${PUBLIC_IP}:8001 \
    -addr ${PUBLIC_IP}:4001
  )
  echo "Started etcd-node1 in container $ETCD1"

  ETCD2=$(docker run \
    -name etcd-node2 \
    -d \
    -p 4002:4002 \
    -p 8002:8002 \
    coreos/etcd \
    -peer-addr ${PUBLIC_IP}:8002 \
    -addr ${PUBLIC_IP}:4002 \
    -peers ${PUBLIC_IP}:8001,${PUBLIC_IP}:8002,${PUBLIC_IP}:8003
  )
  echo "Started etcd-node2 in container $ETCD2"

  ETCD3=$(docker run \
    -name etcd-node3 \
    -d \
    -p 4003:4003 \
    -p 8003:8003 \
    coreos/etcd \
    -peer-addr ${PUBLIC_IP}:8003 \
    -addr ${PUBLIC_IP}:4003 \
    -peers ${PUBLIC_IP}:8001,${PUBLIC_IP}:8002,${PUBLIC_IP}:8003
  )
  echo "Started etcd-node3 in container $ETCD3"
}

_start_blueflood() {
  BLUEFLOOD=$(docker run \
    -p 7000:7000 \
    -p 7001:7001 \
    -p 7199:7199 \
    -p 9160:9160 \
    -p 9042:9042 \
    -p 19000:19000 \
    -p 20000:20000 \
    -d \
    blueflood
  )
  echo "Started BLUEFLOOD in container $BLUEFLOOD"
}

start() {
  _update_local_images
  _start_etcd
  #_start_blueflood
}

_update_local_images() {
  echo
  #docker build -no-cache -rm -t blueflood src/blueflood/demo/docker
}

update() {
  _update_local_images
}

case "$1" in
  restart)
    killz
    start
    ;;
  start)
    start
    ;;
  stop)
    stop
    ;;
  kill)
    killz
    ;;
  update)
    update
    ;;
  init)
    init
    ;;
  status)
    docker ps
    ;;
  run-dev)
    run_dev
    ;;
  *)
    echo $"Usage: $0 {start|stop|init|run-dev|kill|update|restart|status|ssh}"
    RETVAL=1
    ;;
esac
