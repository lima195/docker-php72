#!make

## Edit this vars:
PROJECT=imotopecas
MYSQL_DUMP_FILE=database.sql
BASE_URL=www.imotopecas.localhost

## CUSTOM VARS
BASE_URL_STORE_2=lojista.imotopecas.localhost

## Do not edit vars above:
#================================================================#

DOCKER_DIR=docker-php72

NGINX_HOST=172.22.0.102
PHP_DOCKER=docker-$(PROJECT)_php
NGINX_DOCKER=docker-$(PROJECT)_nginx
MYSQL_DOCKER=docker-$(PROJECT)_mysql
ASSETS_DOCKER=docker-$(PROJECT)_assets
NGINX_WEB_ROOT=/usr/share/nginx/www

MYSQL_DUMP_FILE_DIR=../mysql_dump
MYSQL_USER=$(PROJECT)
MYSQL_PASS=root
MYSQL_DB_NAME=root
MYSQL_HOST=172.22.0.108
MYSQL_PORT=3306

MAGENTO1_LOCAL_XML=./etc/magento/app/etc/local.xml
MAGENTO1_LOCAL_XML_TO=app/etc/local.xml
MAGENTO1_MAGERUN=n98-magerun.phar
MAGENTO1_MAGERUN_TO=/usr/local/bin

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
	@echo " == Magento 1 =="
	@echo " - make magento1_update_core_config_urls"
	@echo " - make magento1_create_localxml"
	@echo " - make magento1_magerun_install"
	@echo " - make magento1_magerun_create_admin"
	@echo " - make magento1_clear_cache"
	@echo " - make magento1_set_permissions"
	@echo " "
	@echo " == Custom tasks for project =="
	@echo " - make magento1_update_core_config_urls_store_2 (Needed to access lojista store view)"
	@echo " - make create_dns_host_store_2 (Needed to access lojista store view)"
	@echo " - make minify_js"
	@echo " "

## TASKS

## Custom Tasks

magento1_update_core_config_urls_store_2:
	make magento_update_baseurl
	sudo docker exec -it $(MYSQL_DOCKER) sh -c "mysql -u $(MYSQL_USER) -p$(MYSQL_PASS) -h $(MYSQL_HOST) $(MYSQL_DB_NAME) -e \"UPDATE core_config_data SET value = 'http://$(BASE_URL_STORE_2)/' WHERE path in ('web/unsecure/base_url', 'web/secure/base_url') AND scope = 'stores' AND scope_id = '2'\"" -P $(MYSQL_PORT)

create_dns_host_store_2:
	sudo -- sh -c "echo '$(NGINX_HOST) $(BASE_URL_STORE_2)' >> /etc/hosts";

minify_js:
	sudo docker exec -it $(ASSETS_DOCKER) sh -c "gulp min:js"

### Do not edit tasks above
#================================================================#

## Database Tasks

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

## Docker Tasks

docker_up:
	sudo docker-compose up -d

## Host Tasks

create_dns_host:
	sudo -- sh -c "echo '$(NGINX_HOST) $(BASE_URL)' >> /etc/hosts";

## Magento Tasks

magento1_update_core_config_urls:
	sudo docker exec -it $(MYSQL_DOCKER) sh -c "mysql -u $(MYSQL_USER) -p$(MYSQL_PASS) -h $(MYSQL_HOST) $(MYSQL_DB_NAME) -e \"UPDATE core_config_data SET value = 'http://$(BASE_URL)/' WHERE path in ('web/unsecure/base_url', 'web/secure/base_url')\"" -P $(MYSQL_PORT)

magento1_create_localxml:
	sudo docker cp $(MAGENTO1_LOCAL_XML) $(NGINX_DOCKER):/$(MAGENTO1_LOCAL_XML_TO);

magento1_magerun_install:
	sudo docker cp ./bin/$(MAGENTO1_MAGERUN) $(PHP_DOCKER):$(MAGENTO1_MAGERUN);
	sudo docker cp ./bin/$(MAGENTO1_MAGERUN) $(PHP_DOCKER):$(MAGENTO1_MAGERUN_TO)/$(MAGENTO1_MAGERUN);

magento1_magerun_create_admin:
	sudo docker exec -it $(PHP_DOCKER) sh -c "$(MAGENTO1_MAGERUN) admin:user:create"

magento1_clear_cache:
	sudo docker exec -it $(NGINX_DOCKER) sh -c "rm -rf var/cache/*; rm -rf var/session/*;"

magento1_set_permissions:
	sudo docker exec -it $(NGINX_DOCKER) sh -c "chown 1000:1000 $(NGINX_WEB_ROOT)/ -R; chmod 777 -R $(NGINX_WEB_ROOT)/var/ $(NGINX_WEB_ROOT)/media/"


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
