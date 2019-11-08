#!make

## Edit this vars:

MYSQL_DUMP_FILE=database.sql
BASE_URL=app

## CUSTOM VARS

## Do not edit vars above:

DOCKER_DIR=docker

NGINX_HOST=172.22.0.102
PHP_DOCKER=docker-app_php
NGINX_DOCKER=docker-app_nginx
MYSQL_DOCKER=docker-app_mysql
NGINX_WEB_ROOT=/usr/share/nginx/www

MYSQL_DUMP_FILE_DIR=../mysql_dump
MYSQL_USER=app
MYSQL_PASS=root
MYSQL_DB_NAME=root
MYSQL_HOST=172.22.0.108
MYSQL_PORT=3306

PHP_XDEBUG_INI=/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
PHP_XDEBUG_INI_HOST_IP=$(HOST_IP)

default:
	@echo "Please, specify a task to run:"
	@echo " "
	@echo " == Instal All =="
	@echo " - make install"
	@echo " "
	@echo " == Database =="
	@echo " - make db_install_pv"
	@echo " - make db_import"
	@echo " - make db_import_pv"
	@echo " - make db_drop_tables"
	@echo " "
	@echo " == Docker =="
	@echo " - make docker_up"
	@echo " "
	@echo " == Host =="
	@echo " - make create_dns_host"
	@echo " "
	@echo " == Custom tasks for project =="
	@echo " "

## TASKS

## Custom Tasks



# Do not edit tasks above

db_install_pv:
	sudo docker exec -it $(MYSQL_DOCKER) sh -c "apt-get update; apt-get install -y pv"

db_import:
	sudo docker cp $(MYSQL_DUMP_FILE_DIR)/$(MYSQL_DUMP_FILE) $(MYSQL_DOCKER):/$(MYSQL_DUMP_FILE);
	sudo docker exec -it $(MYSQL_DOCKER) sh -c "mysql -u $(MYSQL_USER) -p$(MYSQL_PASS) -h $(MYSQL_HOST) $(MYSQL_DB_NAME) < /$(MYSQL_DUMP_FILE) -P $(MYSQL_PORT)"

db_import_pv:
	sudo docker cp $(MYSQL_DUMP_FILE_DIR)/$(MYSQL_DUMP_FILE) $(MYSQL_DOCKER):/$(MYSQL_DUMP_FILE);
	sudo docker exec -it $(MYSQL_DOCKER) sh -c "pv $(MYSQL_DUMP_FILE) | mysql -u $(MYSQL_USER) -p$(MYSQL_PASS) -h $(MYSQL_HOST) -P $(MYSQL_PORT) $(MYSQL_DB_NAME)"

db_drop_tables:
	sudo docker exec -it $(MYSQL_DOCKER) sh -c "mysql -u $(MYSQL_USER) -p$(MYSQL_PASS) -h $(MYSQL_HOST) -P $(MYSQL_PORT) --silent --skip-column-names -e \"SHOW TABLES\" $(MYSQL_DB_NAME) | xargs -L1 -I% echo 'SET FOREIGN_KEY_CHECKS = 0; DROP TABLE %;' | mysql -u $(MYSQL_USER) -p$(MYSQL_PASS) -v $(MYSQL_DB_NAME)"

docker_up:
	sudo docker-compose up -d

create_dns_host:
	sudo -- sh -c "echo '$(NGINX_HOST) $(BASE_URL)' >> /etc/hosts";

install:
	make docker_up
	make db_install_pv
	make db_import_pv
	make create_dns_host

PHONY: \
	db_install_pv \
	db_import \
	db_import_pv \
	db_drop_tables \
	create_dns_host \
	docker_up \
	install
