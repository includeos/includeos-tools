#!/bin/bash

docker stop jenkins-nginx
docker rm jenkins-nginx

docker run --name jenkins-nginx -v /home/ubuntu/file_hosting:/usr/share/nginx/html:ro -p 8080:80 -d nginx
