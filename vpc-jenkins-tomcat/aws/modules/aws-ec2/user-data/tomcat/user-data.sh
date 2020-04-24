#!/bin/bash

# Docker installation

yum install -y docker

systemctl start docker

systemctl enable docker

systemctl status docker

# tomcat Container

Manaager_Gui_User_Name="tomcat"
Manager_Gui_Password="cba!@#$%"

Manager_Gui_and_Script_User_Name="admin"
Manager_Gui_and_Script_Password="saqlainmushtaq.com.pk"

Manager_Script_User_Name="qasim"
Manager_Script="saqlainmushtaq.com"

Host_Manager_User="Paradise"
Host_Manager_User_Password="Islam"




# persistent volumes example

docker network create devops
docker volume create tomcat-devops
docker volume create tomcat-devops-webapps

docker run --name tomcat-devops --network="devops" -v tomcat-devops:/usr/local/tomcat/conf -v tomcat-devops-webapps:/usr/local/tomcat/webapps  --restart unless-stopped -d tomcat:8.0


docker exec tomcat-devops apt update -y

docker exec tomcat-devops cp /usr/local/tomcat/conf/tomcat-users.xml /usr/local/tomcat/conf/tomcat-users.xml-orig

cat << EOF  > /var/lib/docker/volumes/tomcat-devops/_data/tomcat-users.xml
<?xml version='1.0' encoding='utf-8'?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at
      http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<!--
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
-->
<!--
  NOTE:  By default, no user is included in the "manager-gui" role required
  to operate the "/manager/html" web application.  If you wish to use this app,
  you must define such a user - the username and password are arbitrary. It is
  strongly recommended that you do NOT use one of the users in the commented out
  section below since they are intended for use with the examples web
  application.
-->
<!--
  NOTE:  The sample user and role entries below are intended for use with the
  examples web application. They are wrapped in a comment and thus are ignored
  when reading this file. If you wish to configure these users for use with the
  examples web application, do not forget to remove the <!.. ..> that surrounds
  them. You will also need to set the passwords to something appropriate.
-->
<!--
  <role rolename="tomcat"/>
  <role rolename="role1"/>
  <user username="tomcat" password="<must-be-changed>" roles="tomcat"/>
  <user username="both" password="<must-be-changed>" roles="tomcat,role1"/>
  <user username="role1" password="<must-be-changed>" roles="role1"/>
</tomcat-users>
-->
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
<role rolename="manager-gui"/>
  <role rolename="manager-script"/>
  <user username="$Manaager_Gui_User_Name" password="$Manager_Gui_Password" roles="manager-gui"/>
  <user username="$Manager_Gui_and_Script_User_Name" password="$Manager_Gui_and_Script_Password" roles="manager-gui,manager-script"/>
  <user username="$Manager_Script_User_Name" password="$Manager_Script" roles="manager-script"/>
  <user username="$Host_Manager_User" password="$Host_Manager_User_Password" roles="admin-gui"/>
</tomcat-users>
EOF

docker restart tomcat-devops

# END

# Nginx Container

mkdir -p ~/ssl/certs

#2
mkdir -p ~/nginx/conf.d

#3
#openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ~/ssl/certs/nginx-selfsigned.key -out ~/ssl/certs/nginx-selfsigned.crt
openssl req \
    -new \
    -newkey rsa:4096 \
    -days 365 \
    -nodes \
    -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
    -keyout ~/ssl/certs/nginx-selfsigned.key \
    -out ~/ssl/certs/nginx-selfsigned.crt
#4
openssl dhparam -out ~/ssl/certs/dhparam.pem 2048

#5
cd ~/nginx/conf.d

#6
apt update -y  2> /dev/null
apt install -y vim 2> /dev/null
yum update -y  2> /dev/null
yum install -y vim 2> /dev/null

#7
echo '
server {
  listen 80;
  server_name tomcat.saqlainmushtaq.com;
  return 301 https://$host$request_uri;
}
server {
  server_name tomcat.saqlainmushtaq.com;
  listen 443 ssl;
  ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
  ssl_certificate_key /etc/ssl/certs/nginx-selfsigned.key;
  ssl_dhparam /etc/ssl/certs/dhparam.pem;

    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers    TLS-CHACHA20-POLY1305-SHA256:TLS-AES-256-GCM-SHA384:TLS-AES-128-GCM-SHA256:HIGH:!aNULL:!MD5;



location / {
    proxy_set_header        Host $host:$server_port;
    proxy_set_header        X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Proto $scheme;
    proxy_redirect http:// https://;
    proxy_pass              http://tomcat-devops:8080;
    # Required for new HTTP-based CLI
    proxy_http_version 1.1;
    proxy_request_buffering off;

       }
}' >  ~/nginx/conf.d/server.conf

#8
docker run --name nginx --network=devops --restart unless-stopped -v ~/ssl/certs:/etc/ssl/certs -v ~/nginx/conf.d:/etc/nginx/conf.d -p 443:443 -p 80:80 -d nginx


#END
