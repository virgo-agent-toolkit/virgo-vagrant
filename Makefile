.PHONY:

PUBLIC_IP=$(shell ifconfig eth1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $$1}')
DISCOVERY_URL=http://$(PUBLIC_IP):5001/v2/keys/_etcd/registry/

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

blueflood:
	docker build -no-cache -rm -t blueflood src/blueflood/demo/docker

build:
	docker build -no-cache -rm -t virgo-update-service src/virgo-update-service

shipyard:
	@sudo wget https://github.com/shipyard/shipyard-agent/releases/download/v0.0.8/shipyard-agent -O /usr/local/bin/shipyard-agent
	@sudo chmod +x /usr/local/bin/shipyard-agent

upgrade-service-add-one:
	-@PORT=`shuf -i 2000-65000 -n 1` ; \
	  docker run -d -p $$PORT:$$PORT virgo-update-service --addr $(PUBLIC_IP):$$PORT --peers $(PUBLIC_IP):4001 --peers $(PUBLIC_IP):4002 --peers $(PUBLIC_IP):4003 --bind-addr 0.0.0.0:$$PORT -t /var/service/upgrade-service.htpasswd -u $(TEST_USERNAME) -a $(TEST_APIKEY) -s secret > /dev/null

upgrade-service:
	-@docker run -name upg0-vagrant -d -p 34003:34003 virgo-update-service --addr $(PUBLIC_IP):34003 --peers $(PUBLIC_IP):4001 --peers $(PUBLIC_IP):4002 --peers $(PUBLIC_IP):4003 --bind-addr 0.0.0.0:34003 -t /var/service/upgrade-service.htpasswd -u $(TEST_USERNAME) -a $(TEST_APIKEY) -s secret > /dev/null
	-@docker run -name upg1-vagrant -d -p 34004:34004 virgo-update-service --addr $(PUBLIC_IP):34004 --peers $(PUBLIC_IP):4001 --peers $(PUBLIC_IP):4002 --peers $(PUBLIC_IP):4003 --bind-addr 0.0.0.0:34004 -t /var/service/upgrade-service.htpasswd -u $(TEST_USERNAME) -a $(TEST_APIKEY) -s secret > /dev/null
	-@docker run -name upg2-vagrant -d -p 34006:34006 virgo-update-service --addr $(PUBLIC_IP):34006 --peers $(PUBLIC_IP):4001 --peers $(PUBLIC_IP):4002 --peers $(PUBLIC_IP):4003 --bind-addr 0.0.0.0:34006 -t /var/service/upgrade-service.htpasswd -u $(TEST_USERNAME) -a $(TEST_APIKEY) -s secret > /dev/null

etcd:
	docker run -name etcd-node1 -d -p 4001:4001 -p 8001:8001 coreos/etcd -peer-addr $(PUBLIC_IP):8001 -addr $(PUBLIC_IP):4001 -discovery $(DISCOVERY_URL)
	docker run -name etcd-node2 -d -p 4002:4002 -p 8002:8002 coreos/etcd -peer-addr $(PUBLIC_IP):8002 -addr $(PUBLIC_IP):4002 -discovery $(DISCOVERY_URL)
	docker run -name etcd-node3 -d -p 4003:4003 -p 8003:8003 coreos/etcd -peer-addr $(PUBLIC_IP):8003 -addr $(PUBLIC_IP):4003 -discovery $(DISCOVERY_URL)

discovery:
	-@docker run -name etcd-disc0 -d -p 5001:5001 -p 9001:9001 coreos/etcd -addr $(PUBLIC_IP):5001 -peer-addr $(PUBLIC_IP):9001

run: discovery etcd upgrade-service
	@docker ps

clean: clean-images

clean-images:
	-@docker images -q | xargs docker rmi

stop:
	-@docker ps -q | xargs docker kill > /dev/null
	-@docker ps -a -q | xargs docker rm > /dev/null
