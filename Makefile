.PHONY:

PUBLIC_IP=$(shell ifconfig eth1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $$1}')

all:
	@echo usage

fetch: build
	docker pull samalba/docker-registry

registry:
	docker run -name internal_registry -p 5000:5000 -d samalba/docker-registry

build:
	docker build -no-cache -rm -t blueflood src/blueflood/demo/docker

shipyard:
	@sudo wget https://github.com/shipyard/shipyard-agent/releases/download/v0.0.8/shipyard-agent -O /usr/local/bin/shipyard-agent
	@sudo chmod +x /usr/local/bin/shipyard-agent

etcd:
	docker run  -name etcd-node1 -d -p 4001:4001 -p 8001:8001 coreos/etcd -peer-addr $(PUBLIC_IP):8001 -addr $(PUBLIC_IP):4001
	docker run  -name etcd-node2 -d -p 4002:4002 -p 8002:8002 coreos/etcd -peer-addr $(PUBLIC_IP):8002 -addr $(PUBLIC_IP):4002 -peers $(PUBLIC_IP):8001,$(PUBLIC_IP):8002,$(PUBLIC_IP):8003
	docker run  -name etcd-node3 -d -p 4003:4003 -p 8003:8003 coreos/etcd -peer-addr $(PUBLIC_IP):8003 -addr $(PUBLIC_IP):4003 -peers $(PUBLIC_IP):8001,$(PUBLIC_IP):8002,$(PUBLIC_IP):8003

blueflood:
	docker run -p 7000:7000 -p 7001:7001 -p 7199:7199 -p 9160:9160 -p 9042:9042 -p 19000:19000 -p 20000:20000 -d blueflood

run: etcd
	@docker ps

clean-images:
	-@docker images -q | xargs docker rmi

stop:
	-@docker ps -q | xargs docker kill > /dev/null
	-@docker ps -a -q | xargs docker rm > /dev/null
