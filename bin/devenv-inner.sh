#/bin/bash

cd `dirname $0`

DIR="$( cd "$( dirname "$0" )" && pwd )"
APPS=${APPS:-/data/apps}

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

  update_local_images
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
  ETCD0=$(docker run \
    -name etcd0 \
    -p 4001:4001 \
    -d \
    coreos/etcd
  )
  echo "Started ETCD0 in container $ETCD0"
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
  _start_blueflood
}

_update_local_images() {
  docker build -rm -t blueflood src/blueflood/demo/docker
}

update() {
  apt-get update
  apt-get install -y lxc-docker
  cp /vagrant/vagrant/etc/docker/docker /etc/default/docker

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
