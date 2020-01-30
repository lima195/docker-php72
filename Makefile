#!make

## Edit this vars:
PROJECT=imotopecas
MYSQL_DUMP_FILE=dumpImotopecas20200110.sql
BASE_URL=www.imotopecas.localhost
# USE_SUDO=sudo

## CUSTOM VARS
BASE_URL_STORE_2=seller.localhost

## Do not edit vars above:
#================================================================#

DOCKER_DIR=docker-php72

NGINX_HOST=172.22.0.102
PHP_DOCKER=docker-$(PROJECT)_php
NGINX_DOCKER=docker-$(PROJECT)_nginx
MYSQL_DOCKER=docker-$(PROJECT)_mysql
ASSETS_DOCKER=docker-$(PROJECT)_assets
NGINX_WEB_ROOT=/usr/share/nginx/www

MYSQL_DUMP_FILE_DIR=../databases
MYSQL_USER=$(PROJECT)
MYSQL_PASS=$(PROJECT)
MYSQL_DB_NAME=$(PROJECT)
MYSQL_HOST=172.22.0.108
MYSQL_PORT=3306

MAGENTO1_LOCAL_XML=./etc/magento/app/etc/local.xml
MAGENTO1_LOCAL_XML_TO=/usr/share/nginx/www/app/etc/
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
	@echo " - // if you get the fallowing error: ERROR: Pool overlaps with other one on this address space"
	@echo " - make docker_network_prune"
	@echo " - make install_docker"
	@echo " - make docker_restart_containers"
	@echo " - make docker_reinstall_containers"
	@echo " "
	@echo " == PHP xdebug config =="
	@echo " - make xdebug_tutorial"
	@echo " - make get_xdebugso_file"
	@echo " - make get_xdebug_ini"
	@echo " - make config_xdebug_ini"
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
	@echo " - make minjs"
	@echo " "

## TASKS

## Custom Tasks

magento1_update_core_config_urls_store_2:
	$(USE_SUDO) docker exec -it $(MYSQL_DOCKER) sh -c "mysql -u $(MYSQL_USER) -p$(MYSQL_PASS) -h $(MYSQL_HOST) $(MYSQL_DB_NAME) -e \"UPDATE core_config_data SET value = 'http://$(BASE_URL_STORE_2)/' WHERE path in ('web/unsecure/base_url', 'web/secure/base_url') AND scope = 'stores' AND scope_id = '2'\"" -P $(MYSQL_PORT);
	make magento1_show_core_config_data_urls

create_dns_host_store_2:
	echo '$(NGINX_HOST) $(BASE_URL_STORE_2)' >> /etc/hosts;

npm_install:
	$(USE_SUDO) docker exec -it $(ASSETS_DOCKER) sh -c "npm install";

minjs:
	$(USE_SUDO) docker exec -it $(ASSETS_DOCKER) sh -c "gulp min:js";
	sudo chown `whoami`:`whoami` ../web/node_modules/ -R;
	sudo chown `whoami`:`whoami` ../web/public/ -R;

magento1_to_localhost:
	$(USE_SUDO) docker exec -it $(MYSQL_DOCKER) sh -c "mysql -u $(MYSQL_USER) -p$(MYSQL_PASS) -h $(MYSQL_HOST) $(MYSQL_DB_NAME) -e \"UPDATE core_config_data SET value = 'http://localhost/' WHERE path in ('web/unsecure/base_url', 'web/secure/base_url')\"" -P $(MYSQL_PORT);
	make magento1_show_core_config_data_urls;
	cd ../web/;
	rm -rf cache/* session/*;
	sudo echo 'localhost $(BASE_URL)' >> /etc/hosts;


### Do not edit tasks above
#================================================================#

## Database Tasks

db_install_pv:
	$(USE_SUDO) docker exec -it $(MYSQL_DOCKER) sh -c "apt-get update; apt-get install -y pv"

db_import:
	$(USE_SUDO) docker cp $(MYSQL_DUMP_FILE_DIR)/$(MYSQL_DUMP_FILE) $(MYSQL_DOCKER):/$(MYSQL_DUMP_FILE);
	$(USE_SUDO) docker exec -it $(MYSQL_DOCKER) sh -c "mysql -u $(MYSQL_USER) -p$(MYSQL_PASS) -h $(MYSQL_HOST) $(MYSQL_DB_NAME) < /$(MYSQL_DUMP_FILE) -P $(MYSQL_PORT)"

db_import_pv:
	$(USE_SUDO) docker cp $(MYSQL_DUMP_FILE_DIR)/$(MYSQL_DUMP_FILE) $(MYSQL_DOCKER):/$(MYSQL_DUMP_FILE);
	$(USE_SUDO) docker exec -it $(MYSQL_DOCKER) sh -c "pv $(MYSQL_DUMP_FILE) | mysql -u $(MYSQL_USER) -p$(MYSQL_PASS) -h $(MYSQL_HOST) -P $(MYSQL_PORT) $(MYSQL_DB_NAME)"

db_drop_tables:
	$(USE_SUDO) docker exec -it $(MYSQL_DOCKER) sh -c "mysql -u $(MYSQL_USER) -p$(MYSQL_PASS) -h $(MYSQL_HOST) -P $(MYSQL_PORT) --silent --skip-column-names -e \"SHOW TABLES\" $(MYSQL_DB_NAME) | xargs -L1 -I% echo 'SET FOREIGN_KEY_CHECKS = 0; DROP TABLE %;' | mysql -u $(MYSQL_USER) -p$(MYSQL_PASS) -v $(MYSQL_DB_NAME)"

## Docker Tasks


_install_docker:
	sudo apt-get update;
	sudo apt-get install \
	    apt-transport-https \
	    ca-certificates \
	    curl \
	    gnupg-agent \
	    software-properties-common;
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -;
	sudo add-apt-repository \
	   "deb [arch=arm64] https://download.docker.com/linux/ubuntu \
	   $(lsb_release -cs) \
	   stable";
	sudo apt-get update;
	sudo apt-get install docker-ce docker-ce-cli containerd.io;
	sudo usermod -aG docker `whoami`;
	docker -v;

_install_docker_compose:
	sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose;
	sudo chmod +x /usr/local/bin/docker-compose;
	sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose;
	docker-compose --version;

docker_up:
	$(USE_SUDO) docker-compose up -d

# if you get the fallowing error: ERROR: Pool overlaps with other one on this address space
docker_network_prune:
	$(USE_SUDO) docker network prune;
	@echo " Finished!"

docker_restart_containers:
	@echo " "
	@echo " Stopping containers"
	@echo " "
	$(USE_SUDO) docker-compose down; 
	@echo " "
	@echo " Starting containers"
	@echo " "
	$(USE_SUDO) docker-compose up -d; 
	@echo " "
	@echo " Finished!"
	@echo " "

docker_reinstall_containers:
	$(USE_SUDO) docker-compose down; 
	$(USE_SUDO) sudo chown `whoami`:`whoami` volumes -R; 
	$(USE_SUDO) docker-compose up -d --build;
	@echo " "
	@echo " Finished!"
	@echo " "

## PHP xdebug config

xdebug_tutorial:
	@echo " == PHP xdebug config =="
	@echo " "
	@echo " STEP 1 - find the xdebug.so in $(PHP_DOCKER), will be the first result of:"
	@echo " "
	$(USE_SUDO) docker exec -it $(PHP_DOCKER) sh -c "cd /usr/local/lib/php/extensions/; find -iname '*xdebug.so';";
	@echo " "
	@echo " STEP 2 - copy the path of xdebug.so"
	@echo " "
	@echo " STEP 3 - you need to replace 'zend_extension' with the path of xdebug.so"
	@echo " "
	@echo " ==========================================================="
	@echo " EXAMPLE:"
	@echo " 	in STEP 1, if you get: ./no-debug-non-zts-20170718/xdebug.so"
	@echo " 	and in your docker-php-ext-xdebug.ini, if you have at first line:"
	@echo " "
	@echo "		 	zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20160503/xdebug.so"
	@echo " "
	@echo " 	you will need replace only this part:"
	@echo " "
	@echo " 	from: /no-debug-non-zts-20160503/xdebug.so"
	@echo " 	to: ./no-debug-non-zts-20170718/xdebug.so"
	@echo " ==========================================================="
	@echo " "
	@echo " See your xdebug.ini config:"
	@echo " "
	$(USE_SUDO) docker exec -it $(PHP_DOCKER) sh -c "cat /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini;";
	@echo " "
	@echo " STEP 4 - run 'make config_xdebug_ini' to edit xdebug.ini file"
	@echo " 	make config_xdebug_ini"
	@echo " "
	@echo " STEP 5 - restart containers"
	@echo " 	make docker_restart_containers"
	@echo " "
	@echo " Finished!"
	@echo " "


get_xdebugso_file:
	$(USE_SUDO) docker exec -it $(PHP_DOCKER) sh -c "cd /usr/local/lib/php/extensions/; find -iname '*xdebug.so';";

get_xdebug_ini:
	$(USE_SUDO) docker exec -it $(PHP_DOCKER) sh -c "cat /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini;";

config_xdebug_ini:
	$(USE_SUDO) docker exec -it $(PHP_DOCKER) sh -c "vim /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini;";


## Host Tasks

create_dns_host:
	echo '$(NGINX_HOST) $(BASE_URL)' >> /etc/hosts;

## Magento Tasks

magento1_update_core_config_urls:
	$(USE_SUDO) docker exec -it $(MYSQL_DOCKER) sh -c "mysql -u $(MYSQL_USER) -p$(MYSQL_PASS) -h $(MYSQL_HOST) $(MYSQL_DB_NAME) -e \"UPDATE core_config_data SET value = 'http://$(BASE_URL)/' WHERE path in ('web/unsecure/base_url', 'web/secure/base_url')\"" -P $(MYSQL_PORT);
	make magento1_show_core_config_data_urls

magento1_create_localxml:
	$(USE_SUDO) docker cp $(MAGENTO1_LOCAL_XML) $(NGINX_DOCKER):$(MAGENTO1_LOCAL_XML_TO);

magento1_magerun_install:
	$(USE_SUDO) docker cp ./bin/$(MAGENTO1_MAGERUN) $(PHP_DOCKER):$(MAGENTO1_MAGERUN);
	$(USE_SUDO) docker cp ./bin/$(MAGENTO1_MAGERUN) $(PHP_DOCKER):$(MAGENTO1_MAGERUN_TO)/$(MAGENTO1_MAGERUN);

magento1_magerun_create_admin:
	$(USE_SUDO) docker exec -it $(PHP_DOCKER) sh -c "$(MAGENTO1_MAGERUN) admin:user:create"

magento1_magerun_reindex_all:
	$(USE_SUDO) docker exec -it $(PHP_DOCKER) sh -c "$(MAGENTO1_MAGERUN) index:reindex:all"

magento1_magerun_disable_caches:
	$(USE_SUDO) docker exec -it $(PHP_DOCKER) sh -c "$(MAGENTO1_MAGERUN) cache:disable"

magento1_clear_cache:
	$(USE_SUDO) docker exec -it $(NGINX_DOCKER) sh -c "rm -rf var/cache/*; rm -rf var/session/*;"

magento1_set_permissions:
	$(USE_SUDO) docker exec -it $(NGINX_DOCKER) sh -c "chown 1000:1000 $(NGINX_WEB_ROOT)/ -R; chmod 777 -R $(NGINX_WEB_ROOT)/var/ $(NGINX_WEB_ROOT)/media/"

magento1_show_core_config_data_urls:
	$(USE_SUDO) docker exec -it $(MYSQL_DOCKER) sh -c "mysql -u $(MYSQL_USER) -p$(MYSQL_PASS) -h $(MYSQL_HOST) $(MYSQL_DB_NAME) -e \"SELECT * FROM core_config_data WHERE path in ('web/unsecure/base_url', 'web/secure/base_url')\"" -P $(MYSQL_PORT)

install:
	make docker_up
	make db_install_pv
	make db_import_pv
	make create_dns_host

install_magento:
	make docker_up
	make db_install_pv
	make db_import_pv
	make magento1_update_core_config_urls
	make magento1_update_core_config_urls_store_2
	make magento1_magerun_install
	make magento1_create_localxml
	make magento1_set_permissions
	make magento1_clear_cache
	sudo make create_dns_host
	sudo make create_dns_host_store_2
	make magento1_magerun_create_admin

install_docker:
	@echo " "
	@echo " Installing Docker"
	@echo " "
	make _install_docker
	@echo " "
	@echo " !!! It's recomended to reboot the system for apply docker permissions to remove the necessity for running commands with sudo !!!"
	@echo " "
	@echo " Installing Docker-compose"
	@echo " "
	make _install_docker_compose
	@echo " "
	@echo " Finished"
	@echo " "

PHONY: \
	db_install_pv \
	db_import \
	db_import_pv \
	db_drop_tables \
	create_dns_host \
	docker_up \
	install
