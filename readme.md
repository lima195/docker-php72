<p align="center"><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Docker_%28container_engine%29_logo.svg/1280px-Docker_%28container_engine%29_logo.svg.png"></p>

## Author
	Pedro Henrique Gonçalves de Lima
	phgdl.19@gmail.com
	+55 (11) 97721-2101
	https://www.linkedin.com/in/pedrohgdl/

## Intro
	This docker contains the following containers:

	* Nginx
	* PHP 7.2 (and 7.1)
	* Assets (With Nodejs, Yarn and Grunt)
	* Mysql
	* Adminer

## Structure

	your_project_dir/
		docker-php72/
			assets/
			etc/
			nginx_conf/default
			php71/
			php72/
			volumes/mysql
			docker-compose.yml
			Makefile
		web/ (required - for run the project)
		mysql_dump/ (optional - to storage your database.sql if you have one)

## Settings
	
	This docker is set to run with:

	Mysql credentials:
		user: app (or root)
		pass: root
		database: app
		host: 172.22.0.108
		port: 3306

	Nginx:
		http://app
		* assuming that your project php index is placed at ../web/index

	PHP Xdebug:
		xdebug.remote_enable=1
		xdebug.remote_handler=dbgp
		xdebug.remote_port=9001
		xdebug.remote_autostart=1
		xdebug.remote_connect_back=0
		xdebug.idekey=docker
		xdebug.remote_host=172.22.0.1

	Adminer:
		http://localhost:8222

	Assets:
		gulp version: 
			CLI version: 2.2.0
			Local version: Unknown
		yarn version:
			1.19.1
		nodejs version:
			v13.1.0

	Default dump name file and dir:
		../mysql_dump/database.sql


## Changing Default Settings

	Mysql credentials: 
		./docker-compose.yml lines: 48, 49, 50, 21
		./Makefile lines: 21, 22, 23

	Nginx host:
		./nginx_conf/default.conf line: 11

	PHP changing version 7.1 or 7.2:
		./docker-compose.yml line 29

	PHP Dockerfile:
		./php71/Dockerfile
		./php72/Dockerfile

	Assets Dockerfile:
		./assets/Dockerfile

	[If your project run in public/ dir like Laravel Framework]
		Add /public in:
			./nginx_conf/default.conf line: 12

	Default mysql dump file:
		./Makefile line: 5

## Instalation

	* Get inside docker dir, and run:

	docker-compose up -d;

	* After that, to add a new dns host (assuming that you are using ubuntu) run:

	make create_dns_host;
	
## Extra

	See Makefile tasks, maybe it might be useful or just run:

	make default;	