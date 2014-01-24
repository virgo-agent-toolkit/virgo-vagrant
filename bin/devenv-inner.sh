#/bin/bash
set -e

cd `dirname $0`/..

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
  sudo usermod -a -G docker vagrant
  newgrp docker

  sudo cp /vagrant/etc/default/docker.conf /etc/default/docker.conf
  sudo service restart docker

  if [ ! -f /usr/local/bin/shipyard-agent ] ; then
    sudo wget https://github.com/shipyard/shipyard-agent/releases/download/v0.0.8/shipyard-agent -O /usr/local/bin/shipyard-agent
    sudo chmod +x /usr/local/bin/shipyard-agent
    #apikey=`shipyard-agent -url "http://127.0.0.1:8005" -register|awk '{print $5}'`
    #shipyard-agent -url "http://127.0.0.1:8005" -key $apikey &
  fi
}

start(){
  mkdir -p $APPS/cassandra/data
  mkdir -p $APPS/cassandra/logs

  REGISTRY=$(docker run \
    -name internal_registry \
    -p 5000:5000 \
    -d \
    samalba/docker-registry
  )
  echo "Started REGISTRY in container $REGISTRY"

  SHIPYARD=$(docker run \
    -name shipyard \
    -p 8005:8000 \
    -d \
    shipyard/shipyard
  )
  echo "Started SHIPYARD in container $SHIPYARD"

  mkdir -p $APPS/cassandra/data
  mkdir -p $APPS/cassandra/logs
  CASSANDRA=$(docker run \
    -p 7000:7000 \
    -p 7001:7001 \
    -p 7199:7199 \
    -p 9160:9160 \
    -p 9042:9042 \
    -v $APPS/cassandra/data:/data \
    -v $APPS/cassandra/logs:/logs \
    -d \
    relateiq/cassandra
  )
  echo "Started CASSANDRA in container $CASSANDRA"

  ETCD0=$(docker run \
    -name etcd0 \
    -p 4001:4001 \
    -d \
    coreos/etcd
  )
  echo "Started ETCD0 in container $ETCD0"

  sleep 1
}

update() {
  apt-get update
  apt-get install -y lxc-docker
  cp /vagrant/etc/docker.conf /etc/init/docker.conf

  docker pull relateiq/cassandra
  docker pull shipyard/shipyard
  docker pull samalba/docker-registry
}

run_dev() {
  docker build -t 127.0.0.1:5000/virgo-update-service src/virgo-update-service
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
