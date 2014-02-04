.PHONY:

PUBLIC_IP=$(shell ifconfig eth1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $$1}')

all:
	@echo Targets:
	@echo "      fetch"
	@echo "      registry"
	@echo "      build"
	@echo "      shipyard"
	@echo "      etcd"
	@echo "      run"
	@echo "      stop"

fetch:
	docker pull samalba/docker-registry

registry:
	docker run -name internal_registry -p 5000:5000 -d samalba/docker-registry

build:
	#docker build -no-cache -rm -t blueflood src/blueflood/demo/docker
	docker build -no-cache -rm -t virgo-update-service src/virgo-update-service

shipyard:
	@sudo wget https://github.com/shipyard/shipyard-agent/releases/download/v0.0.8/shipyard-agent -O /usr/local/bin/shipyard-agent
	@sudo chmod +x /usr/local/bin/shipyard-agent

upgrade-service:
	docker run -name upg0-vagrant -d -p 34002:34002 virgo-update-service --peers $(PUBLIC_IP):4001 --peers $(PUBLIC_IP):4002 --peers $(PUBLIC_IP):4003 --bind-addr $(PUBLIC_IP):34002 -t /var/service/upgrade-service.htpasswd -u test -a test -s secret

etcd:
	docker run  -name etcd-node1 -d -p 4001:4001 -p 8001:8001 coreos/etcd -peer-addr $(PUBLIC_IP):8001 -addr $(PUBLIC_IP):4001
	docker run  -name etcd-node2 -d -p 4002:4002 -p 8002:8002 coreos/etcd -peer-addr $(PUBLIC_IP):8002 -addr $(PUBLIC_IP):4002 -peers $(PUBLIC_IP):8001,$(PUBLIC_IP):8002,$(PUBLIC_IP):8003
	docker run  -name etcd-node3 -d -p 4003:4003 -p 8003:8003 coreos/etcd -peer-addr $(PUBLIC_IP):8003 -addr $(PUBLIC_IP):4003 -peers $(PUBLIC_IP):8001,$(PUBLIC_IP):8002,$(PUBLIC_IP):8003

run: etcd upgrade-service
	@docker ps

clean: clean-images

clean-images:
	-@docker images -q | xargs docker rmi

stop:
	-@docker ps -q | xargs docker kill > /dev/null
	-@docker ps -a -q | xargs docker rm > /dev/null
