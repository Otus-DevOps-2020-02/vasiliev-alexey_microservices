USER_NAME = avasiliev

build-all: build-ui build-comment build-post build-prometheus build-blackbox-exporter build-mongodb-exporter

build-ui:
	cd ./src/ui && bash ./docker_build.sh

build-comment:
	cd ./src/comment && bash ./docker_build.sh

build-post:
	cd ./src/post-py && bash ./docker_build.sh

build-blackbox-exporter:
	cd ./monitoring/blackbox && docker build -t ${USER_NAME}/blackbox_exporter .

build-mongodb-exporter:
	cd ./monitoring/mongodb && docker build -t ${USER_NAME}//mongodb_exporter .

build-prometheus:
	cd ./monitoring/prometheus && docker build -t ${USER_NAME}/prometheus .

build-alertmanager:
	cd ./monitoring/alertmanager && docker build -t ${USER_NAME}/alertmanager .

push-all: ui-push comment-push post-push blackbox-exporter-push prometheus-push mongodb-exporter-push

ui-push:
	docker push ${USER_NAME}/ui

comment-push:
	docker push ${USER_NAME}/comment

post-push:
	docker push ${USER_NAME}/post

blackbox-exporter-push:
	docker push ${USER_NAME}/blackbox_exporter

mongodb-exporter-push:
	docker push ${USER_NAME}/mongodb_exporter

prometheus-push:
	docker push ${USER_NAME}/prometheus

alertmanager-push:
	docker push ${USER_NAME}/alertmanager
