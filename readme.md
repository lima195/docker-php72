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
	* Assets (With Nodejs, npm and gulp)
	* Mysql
	* Adminer

## Structure

Your project needed to fallow this structure:

	├── your_project_dir/
	│   ├── docker-php72/ 	(This repo)
	│   ├── web/ 			(required - for run the project)
	│   ├── mysql_dump/ 	(optional - to storage your database.sql if you have one)

## Settings

Mysql credentials:

	user: imotopecas (or root)
	pass: root
	database: imotopecas
	host: 172.22.0.108
	port: 3306

Nginx:

	http://www.imotopecas.com
	http://lojista.imotopecas.com

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

Default dump name file and dir:

	../mysql_dump/database.sql

## Instalation

Requirements
	
	1 - Right structure
	2 - Docker and Docker-compose installed, if not, you can run
		make install_docker;

Get inside docker dir, and run:

	make install_magento;

Access:
	
	http://www.imotopecas.com

or

	http://lojista.imotopecas.com
	
## Minify Javascript

Get inside docker dir, and run:

	make minjs;

## To see all tasks:

Get inside docker dir, and run:
	
	make;