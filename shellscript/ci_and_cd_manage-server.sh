#!/bin/bash -ex

export LOGFILE=/tmp/ci_and_cd_admin-server_script.log
export PASSWORD=DevOps
export APACHE_LISTEN_PORT=81

echo cloud-init RHEL Server Basic Setting Start `date` >> ${LOGFILE}

yum install -y jq sdparm sg3_utils lsscsi x86info diffstat ps_mem arpwatch dropwatch wireshark screen conman logwatch zsh expect pexpect tree hardlink bash-completion tuned tuned-utils >> ${LOGFILE}
/sbin/service tuned start >> ${LOGFILE}
/usr/sbin/tuned-adm profile throughput-performance >> ${LOGFILE}
/usr/sbin/tuned-adm active >> ${LOGFILE}
/sbin/service tuned restart >> ${LOGFILE}
/sbin/chkconfig tuned on >> ${LOGFILE}

echo cloud-init RHEL Server Basic Setting Complate `date` >> ${LOGFILE}


echo cloud-init RHEL IRC-ngird Server Setting Start `date` >> ${LOGFILE}

yum install -y ngircd >> ${LOGFILE}
echo "### Welcome to DevOps Team ###" >> /etc/ngircd.motd
sed -i 's/irc.the.net/localhost.localdomain/g' /etc/ngircd.conf
sed -i "s/;Password = abc/Password = ${PASSWORD}/g" /etc/ngircd.conf
sed -i 's/;Ports = 6667, 6668, 6669/Ports = 6667, 6668, 6669/g' /etc/ngircd.conf
sed -i 's/Listen = 127.0.0.1/Listen = 0.0.0.0/g' /etc/ngircd.conf
sed -i 's/;MaxNickLength = 9/MaxNickLength = 16/g' /etc/ngircd.conf
sed -i 's/;Name = #TheName/Name = DevOps/g' /etc/ngircd.conf
sed -i 's/;Topic = a great topic/Topic = CI and CD/g' /etc/ngircd.conf
sed -i 's/;Modes = tn/Modes = tn/g' /etc/ngircd.conf
/usr/sbin/ngircd --configtest << __EOF__ >> ${LOGFILE}

__EOF__

/bin/egrep -v '^$|^#' /etc/ngircd.conf >> ${LOGFILE}

/sbin/service ngircd start >> ${LOGFILE}
/sbin/chkconfig ngircd on >> ${LOGFILE}

echo cloud-init RHEL IRC-ngird Server Setting Complete `date` >> ${LOGFILE}


echo cloud-init RHEL nginx Server Install Start `date` >> ${LOGFILE}

cat > /etc/yum.repos.d/nginx.repo << 'EOF';
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/rhel/6/\$basearch/
gpgcheck=0
enabled=1
EOF

wget -t 5 -O /tmp/nginx_signing.key http://nginx.org/keys/nginx_signing.key >> ${LOGFILE}
rpm --import /tmp/nginx_signing.key >> ${LOGFILE}

yum clean all >> ${LOGFILE}
yum install -y nginx >> ${LOGFILE}

/sbin/service nginx start >> ${LOGFILE}
/sbin/chkconfig nginx on >> ${LOGFILE}

echo cloud-init RHEL nginx Server Install Complete `date` >> ${LOGFILE}



echo cloud-init RHEL Sphinx Documentation Generator Install Start `date` >> ${LOGFILE}

yum install -y python-pip python-setuptools gcc gcc-c++ >> ${LOGFILE}

/usr/bin/easy_install sphinx >> ${LOGFILE}
/usr/bin/easy_install sphinxjp.themes.sphinxjp >> ${LOGFILE}

echo cloud-init RHEL Sphinx Documentation Generator Install Complete `date` >> ${LOGFILE}




echo cloud-init RHEL Sphinx Sample-Project-WebSite Setting Start `date` >> ${LOGFILE}

#-------------------------------------------------------------
# /usr/bin/sphinx-quickstart
#-------------------------------------------------------------
# Root path for the documentation [.]:
# Separate source and build directories (y/n) [n]:
# Name prefix for templates and static dir [_]: 
# Project name: 
# Author name(s): 
# Project version: 
# Project release [1.0]:
# Source file suffix [.rst]:
# Name of your master document (without suffix) [index]:
# Do you want to use the epub builder (y/n) [n]: 
# autodoc: automatically insert docstrings from modules (y/n) [n]: 
# doctest: automatically test code snippets in doctest blocks (y/n) [n]: 
# intersphinx: link between Sphinx documentation of different projects (y/n) [n]: 
# todo: write "todo" entries that can be shown or hidden on build (y/n) [n]: 
# coverage: checks for documentation coverage (y/n) [n]: 
# pngmath: include math, rendered as PNG images (y/n) [n]: 
# mathjax: include math, rendered in the browser by MathJax (y/n) [n]: 
# ifconfig: conditional inclusion of content based on config values (y/n) [n]: 
# viewcode: include links to the source code of documented Python objects (y/n) [n]: 
# Create Makefile? (y/n) [y]: 
# Create Windows command file? (y/n) [y]: 
#-------------------------------------------------------------

mkdir -p /tmp/sphinx-doc

cd /tmp/sphinx-doc

/usr/bin/sphinx-quickstart << __EOF__ 

n
devops
DevOps
DevOps Project Member
1.0
1.0


y
y
y
y
y
y
y
n
y
y
y
y


__EOF__


sed -i '/#html_use_smartypants = True/a html_use_smartypants = False' /tmp/sphinx-doc/conf.py
sed -i 's/html_theme = /#html_theme = /g' /tmp/sphinx-doc/conf.py
sed -i "/#html_theme =/a html_theme = 'sphinxjp'" /tmp/sphinx-doc/conf.py

make html

cp -pr /tmp/sphinx-doc/devopsbuild/html/* /usr/share/nginx/html/
chown -R nginx:nginx /usr/share/nginx/html

echo cloud-init RHEL Sphinx Sample-Project-WebSite Setting Complete `date` >> ${LOGFILE}


echo cloud-init RHEL nginx Server Setting Start `date` >> ${LOGFILE}

# Basic Authentication File Create
echo "admin:`openssl passwd -apr1 ${PASSWORD}`" >> /etc/nginx/.htpasswd

# Configuration nginx.conf

cat > /etc/nginx/nginx.conf << 'EOF';
user nginx;
worker_processes  4;
worker_priority 0;
worker_rlimit_nofile 8192;

pid         /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {

    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    charset UTF-8;
    server_tokens   off;

    log_format main   '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    log_format ltsv   'time:$time_iso8601\t'
                      'host:$remote_addr\t'
                      'request:$request\t'
                      'method:$request_method\t'
                      'url:$request_uri\t'                      
                      'status:$status\t'
                      'xff:$http_x_forwarded_for\t'
                      'res_size:$bytes_sent\t'                      
                      'body_size:$body_bytes_sent\t'
                      'referer:$http_referer\t'
                      'ua:$http_user_agent\t'
                      'reqsize:$request_length\t'
                      'reqtime:$request_time\t'
                      'apptime:$upstream_response_time';

    access_log  /var/log/nginx/access.log  ltsv;
    error_log   /var/log/nginx/error.log notice;

    sendfile        on;
    tcp_nopush      on;

    keepalive_timeout  120;

    gzip on;
    gzip_types  text/plain
                text/xml
                text/css
                text/javascript
                image/x-icon
                application/xml
                application/rss+xml
                application/json
                application/x-javascript;
    gzip_disable "MSIE [1-6]\.";
    gzip_disable "Mozilla/4";

    ignore_invalid_headers on;
    client_max_body_size 500M;

    # IP-Address Authentication or HTTP Basic Authentication
    satisfy any;

    # Allow IP-Address
    # Corporate Global IP Address
    allow 210.128.115.149;
    allow 180.59.231.234;
    allow 180.43.32.112;

    # Allow IP-Address
    # localhost Private IP Address
    allow 127.0.0.1;

    # Allow IP-Address Ranges
    # VPC Private IP Address
    allow 10.0.0.0/16;

    # Allow IP-Address Ranges
    # Amazon EC2 Public IP Address Ranges Asia Pacific (Tokyo)
    # https://forums.aws.amazon.com/ann.jspa?annID=1701
    allow 175.41.192.0/18;
    allow 46.51.224.0/19;
    allow 176.32.64.0/19;
    allow 103.4.8.0/21;
    allow 176.34.0.0/18;
    allow 54.248.0.0/15;
    allow 54.250.0.0/16;
    allow 54.238.0.0/16;
    allow 54.199.0.0/16;
    allow 54.178.0.0/16;

    # Deny All
    deny all;

    # HTTP Basic Authentication
    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/.htpasswd;

    # Other WebService Configuration File
    include /etc/nginx/conf.d/*.conf;
}
EOF



cat > /etc/nginx/conf.d/server.conf << 'EOF';
server {
    listen       80;
    server_name  localhost;

    location /redmine {
        sendfile off;
        proxy_pass         http://127.0.0.1:81;
        proxy_redirect     default;

        proxy_set_header   Host             $host;
        proxy_set_header   X-Real-IP        $remote_addr;
        proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_max_temp_file_size 0;

        # This is the maximum upload size
        client_max_body_size       1024m;
        client_body_buffer_size    128k;

        proxy_connect_timeout      90;
        proxy_send_timeout         90;
        proxy_read_timeout         90;

        proxy_buffer_size          4k;
        proxy_buffers              4 32k;
        proxy_busy_buffers_size    64k;
        proxy_temp_file_write_size 64k;
    }

    location /subversion {
        sendfile off;
        proxy_pass         http://127.0.0.1:81;
        proxy_redirect     default;

        proxy_set_header   Host             $host;
        proxy_set_header   X-Real-IP        $remote_addr;
        proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_max_temp_file_size 0;

        # This is the maximum upload size
        client_max_body_size       1024m;
        client_body_buffer_size    128k;

        proxy_connect_timeout      90;
        proxy_send_timeout         90;
        proxy_read_timeout         90;

        proxy_buffer_size          4k;
        proxy_buffers              4 32k;
        proxy_busy_buffers_size    64k;
        proxy_temp_file_write_size 64k;
    }

    location /jenkins/userContent {
        # Have nginx handle all the static requests to the userContent folder files
        # NOTE: This is the $JENKINS_HOME dir
        root /var/lib/jenkins/;
        if (!-f $request_filename){
            # This file does not exist, might be a directory or a /**view** url
            rewrite (.*) /$1 last;
            break;
        }
        sendfile on;
    }

    location /jenkins {
        sendfile off;
        proxy_pass         http://127.0.0.1:8080;
        proxy_redirect     default;

        proxy_set_header   Host             $host;
        proxy_set_header   X-Real-IP        $remote_addr;
        proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_max_temp_file_size 0;

        # This is the maximum upload size
        client_max_body_size       100m;
        client_body_buffer_size    128k;

        proxy_connect_timeout      90;
        proxy_send_timeout         90;
        proxy_read_timeout         90;

        proxy_buffer_size          4k;
        proxy_buffers              4 32k;
        proxy_busy_buffers_size    64k;
        proxy_temp_file_write_size 64k;
    }

    location /robots.txt {
        access_log off;
        log_not_found off;
    }

    location /favicon.ico {
        access_log off;
        log_not_found off;
    }

    location ~ /\. { 
        access_log off;
        log_not_found off;
        deny all;
    }

    location ~ ~$ { 
        access_log off;
        log_not_found off;
        deny all;
    }

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

}
EOF



mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf~
mv /etc/nginx/conf.d/example_ssl.conf /etc/nginx/conf.d/example_ssl.conf~

# nginx service restart
/sbin/service nginx configtest >> ${LOGFILE}
/sbin/service nginx reload >> ${LOGFILE}
/sbin/service nginx restart >> ${LOGFILE}

echo cloud-init RHEL nginx Server Setting Complete `date` >> ${LOGFILE}




echo cloud-init RHEL Fluentd Server Install Start `date` >> ${LOGFILE}

cat > /etc/yum.repos.d/td.repo <<'EOF';
[treasuredata]
name=TreasureData
baseurl=http://packages.treasure-data.com/redhat/\$basearch
gpgcheck=1
gpgkey=http://packages.treasure-data.com/redhat/RPM-GPG-KEY-td-agent
EOF

wget -t 5 -O /tmp/RPM-GPG-KEY-td-agent http://packages.treasure-data.com/redhat/RPM-GPG-KEY-td-agent >> ${LOGFILE}
rpm --import /tmp/RPM-GPG-KEY-td-agent >> ${LOGFILE}
yum clean all >> ${LOGFILE}
yum install -y td-agent >> ${LOGFILE}
/sbin/service td-agent start >> ${LOGFILE}
/sbin/chkconfig td-agent on >> ${LOGFILE}

echo cloud-init RHEL Fluentd Server Install Complete `date` >> ${LOGFILE}


echo cloud-init RHEL MongoDB Server Install Start `date` >> ${LOGFILE}

cat > /etc/yum.repos.d/10gen.repo <<'EOF';
[10gen]
name=10gen Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64
gpgcheck=0
enabled=1
EOF

yum install -y mongo-10gen-server mongo-10gen >> ${LOGFILE}
/sbin/service mongod start >> ${LOGFILE}
/sbin/chkconfig mongod on >> ${LOGFILE}

echo cloud-init RHEL MongoDB Server Install Complete `date` >> ${LOGFILE}



echo cloud-init RHEL Fluentd Server Settings Start `date` >> ${LOGFILE}

chgrp td-agent /var/log/messages
chgrp td-agent /var/log/secure
chgrp td-agent /var/log/cron

chmod 644 /var/log/nginx/*
chmod g+rx /var/log/messages
chmod g+rx /var/log/secure
chmod g+rx /var/log/cron


#/usr/lib64/fluent/ruby/bin/fluent-gem update
/usr/lib64/fluent/ruby/bin/fluent-gem update fluent-plugin-mongo >> ${LOGFILE}
/usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-forest >> ${LOGFILE}
/usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-config-expander >> ${LOGFILE}

yum install -y libcurl libcurl-devel >> ${LOGFILE}
/usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-elasticsearch >> ${LOGFILE}

/usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-elb-log >> ${LOGFILE}

yum install -y GeoIP GeoIP-devel >> ${LOGFILE}
/usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-geoip >> ${LOGFILE}


cat > /etc/td-agent/td-agent.conf <<'EOF';
<source>
  type forward
  port 24224
</source>

<source>
  type tail
  format ltsv
  path /var/log/nginx/access.log
  pos_file /var/log/td-agent/nginx.access.pos
  tag nginx.access
</source>
  
<source>
  type config_expander
  <config>
    type tail
    format syslog
    path /var/log/messages
    pos_file /var/log/td-agent/syslog.access.pos
    tag syslog.messages
  </config>
</source>
 
<match nginx.access>
  type mongo
  database nginx
  collection access
  host localhost
  port 27017
  flush_interval 10s
</match>

<match syslog.messages>
  type mongo
  database syslog
  collection messages
  host localhost
  port 27017
  flush_interval 10s
</match>

<match *.**>
  type mongo
  database fluentd
  collection other
  host localhost
  port 27017
  flush_interval 10s
</match>
EOF

/sbin/service td-agent configtest >> ${LOGFILE}
/sbin/service td-agent restart >> ${LOGFILE}

echo cloud-init RHEL Fluentd Server Settings Complete `date` >> ${LOGFILE}



echo cloud-init RHEL Fluentd and MongoDB Test Start `date` >> ${LOGFILE}

/usr/bin/mongo --eval "db.access.find().count()" nginx >> ${LOGFILE}

echo cloud-init RHEL Fluentd and MongoDB Test Complete `date` >> ${LOGFILE}




echo cloud-init RHEL Apache HTTP Server Install Start `date` >> ${LOGFILE}

yum install -y httpd httpd-devel apr-devel apr-util-devel >> ${LOGFILE}
yum install -y openssl-devel readline-devel zlib-devel curl-devel libyaml-devel ImageMagick ImageMagick-devel ipa-pgothic-fonts >> ${LOGFILE}

echo cloud-init RHEL Apache HTTP Server Install Complete `date` >> ${LOGFILE}


echo cloud-init RHEL Apache HTTP Server Settings Start `date` >> ${LOGFILE}

/bin/egrep -v '^$|^#' /etc/httpd/conf/httpd.conf >> ${LOGFILE}

sed -i "s/Listen 80/Listen ${APACHE_LISTEN_PORT}/g" /etc/httpd/conf/httpd.conf 

/bin/egrep -v '^$|^#' /etc/httpd/conf/httpd.conf >> ${LOGFILE}

/sbin/service httpd configtest >> ${LOGFILE}
/sbin/service httpd start >> ${LOGFILE}

echo cloud-init RHEL Apache HTTP Server Settings Complete `date` >> ${LOGFILE}


echo cloud-init RHEL WebDAV+Subversion Install Start `date` >> ${LOGFILE}

yum install -y subversion mod_dav_svn >> ${LOGFILE}

echo cloud-init RHEL WebDAV+Subversion Install Complete `date` >> ${LOGFILE}


echo cloud-init RHEL WebDAV+Subversion Settings Start `date` >> ${LOGFILE}

/usr/bin/svnadmin create /var/www/subversion >> ${LOGFILE}

chown -R apache:apache /var/www/subversion

# Basic Authentication File Create
echo "admin:`openssl passwd -apr1 ${PASSWORD}`" >> /etc/httpd/conf/.htpasswd


cat > /etc/httpd/conf.d/subversion.conf << __EOF__
# Subversion(+WebDAV) Settings
LoadModule dav_svn_module     modules/mod_dav_svn.so
LoadModule authz_svn_module   modules/mod_authz_svn.so

ErrorLog logs/subversion-error.log
LogLevel warn
CustomLog logs/subversion-access.log combined

<Location /subversion>
   
   DAV svn
   SVNPath /var/www/subversion

   Order Allow,Deny

   # Allow IP-Address
   # localhost Private IP Address
   Allow from 127.0.0.1

   # Allow IP-Address
   # Corporate Global IP Address
   Allow from 210.128.115.149
   Allow from 180.59.231.234
   Allow from 180.43.32.112

   # Allow IP-Address Ranges
   # VPC Private IP Address
   Allow from 10.0.0.0/16

   # Allow IP-Address Ranges
   # Amazon EC2 Public IP Address Ranges Asia Pacific (Tokyo)
   # https://forums.aws.amazon.com/ann.jspa?annID=1701
   Allow from 175.41.192.0/18
   Allow from 46.51.224.0/19
   Allow from 176.32.64.0/19
   Allow from 103.4.8.0/21
   Allow from 176.34.0.0/18
   Allow from 54.248.0.0/15
   Allow from 54.250.0.0/16
   Allow from 54.238.0.0/16
   Allow from 54.199.0.0/16
   Allow from 54.178.0.0/16

   AuthType Basic
   AuthName "Subversion repositories"
   AuthUserFile /etc/httpd/conf/.htpasswd
   Require valid-user
</Location>

__EOF__


/bin/egrep -v '^$|^#' /etc/httpd/conf.d/subversion.conf >> ${LOGFILE}

/sbin/service httpd configtest >> ${LOGFILE}
/sbin/service httpd restart >> ${LOGFILE}
/sbin/chkconfig httpd on >> ${LOGFILE}

echo cloud-init RHEL WebDAV+Subversion Settings Complete `date` >> ${LOGFILE}



echo cloud-init RHEL MySQL-Oracle v5.6.x Install Start `date` >> ${LOGFILE}

yum localinstall -y http://repo.mysql.com/yum/mysql-community/el/6/x86_64/mysql-community-release-el6-5.noarch.rpm >> ${LOGFILE}
yum clean all >> ${LOGFILE}
yum install -y mysql-community-server mysql-community-devel mysql-utilities >> ${LOGFILE}
/sbin/chkconfig mysqld on >> ${LOGFILE}

echo cloud-init RHEL MySQL-Oracle v5.6.x Install Complete `date` >> ${LOGFILE}


echo cloud-init RHEL MySQL-Oracle v5.6.x Settings Start `date` >> ${LOGFILE}

cat > /etc/my.cnf << 'EOF';
# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/5.6/en/server-configuration-defaults.html

[mysqld]
#
# Remove leading # and set to the amount of RAM for the most important data
# cache in MySQL. Start at 70% of total RAM for dedicated server, else 10%.
# innodb_buffer_pool_size = 128M
#
# Remove leading # to turn on a very important data integrity option: logging
# changes to the binary log between backups.
# log_bin
#
# Remove leading # to set options mainly useful for reporting servers.
# The server defaults are faster for transactions and fast SELECTs.
# Adjust sizes as needed, experiment to find the optimal values.
# join_buffer_size = 128M
# sort_buffer_size = 2M
# read_rnd_buffer_size = 2M

# InnoDB Parameters
innodb_buffer_pool_size = 8G
innodb_log_file_size = 2G
innodb_thread_concurrency = 8
innodb_buffer_pool_dump_at_shutdown = ON
innodb_buffer_pool_load_at_startup = ON

# MySQL Server System Variables
join_buffer_size = 128M
sort_buffer_size = 2M
query_cache_size = 64M
query_cache_type = 1
query_cache_limit = 2M
tmp_table_size = 64M
max_heap_table_size = 64M

datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock

# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0

skip-character-set-client-handshake
character-set-server = utf8
collation-server = utf8_general_ci
init-connect = SET NAMES utf8

# Recommended in standard MySQL setup
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES

[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

[mysql]
default-character-set = utf8

EOF

/bin/egrep -v '^$|^#' /etc/my.cnf >> ${LOGFILE}

/sbin/service mysqld start >> ${LOGFILE}

/usr/bin/mysql -u root -e "show variables like 'character_set%';"  >> ${LOGFILE}

/usr/bin/mysql_secure_installation << __EOF__

Y
DevOps
DevOps
Y
Y
Y
Y
__EOF__

/usr/bin/mysql -uroot -pDevOps -e "show variables like 'character_set%';" >> ${LOGFILE}

/usr/bin/mysql -uroot -pDevOps << __EOF__
create database db_redmine default character set utf8;
grant all on db_redmine.* to user_redmine@localhost identified by 'DevOps';
flush privileges;
__EOF__

/sbin/service mysqld restart >> ${LOGFILE}

echo cloud-init RHEL MySQL-Oracle v5.6.x Settings Complete `date` >> ${LOGFILE}


echo cloud-init RHEL Ruby v2.0.x Install Start `date` >> ${LOGFILE}

yum localinstall -y http://rpm-repository.s3.amazonaws.com/ruby/ruby-2.0.0.451-1.el6.x86_64.rpm >> ${LOGFILE}

echo cloud-init RHEL Ruby v2.0.x Install Complete `date` >> ${LOGFILE}




echo cloud-init RHEL Redmine v2.5.x Install Start `date` >> ${LOGFILE}

wget -t 5 -O /tmp/redmine-2.5.0.tar.gz http://www.redmine.org/releases/redmine-2.5.0.tar.gz
tar xvzf /tmp/redmine-2.5.0.tar.gz -C /tmp
/bin/mv /tmp/redmine-2.5.0 /var/lib/redmine

echo cloud-init RHEL Redmine v2.5.x Complete Start `date` >> ${LOGFILE}


echo cloud-init RHEL Redmine v2.5.x Settings Start `date` >> ${LOGFILE}

# Redmine Theme and Wiki Help Change
git clone git://github.com/farend/redmine_theme_farend_fancy.git  /var/lib/redmine/public/themes/farend_fancy
wget -t 5 -O /var/lib/redmine/public/help/wiki_syntax.html https://raw.github.com/farend/redmine_wiki_syntax_ja/master/wiki_syntax.html
wget -t 5 -O /var/lib/redmine/public/help/wiki_syntax_detailed.html https://raw.github.com/farend/redmine_wiki_syntax_ja/master/wiki_syntax_detailed.html

mkdir -p /var/lib/redmine/public/plugin_assets
chmod 777 /var/lib/redmine/public/plugin_assets

chown -R root:root /var/lib/redmine

cat > /var/lib/redmine/config/database.yml << __EOF__
# Default setup is given for MySQL with ruby1.9. If you're running Redmine
# with MySQL and ruby1.8, replace the adapter name with `mysql`.
# Examples for PostgreSQL, SQLite3 and SQL Server can be found at the end.
# Line indentation must be 2 spaces (no tabs).

production:
  adapter: mysql2
  database: db_redmine
  host: localhost
  username: user_redmine
  password: DevOps
  encoding: utf8

__EOF__


cat > /var/lib/redmine/config/configuration.yml << __EOF__
# = Redmine configuration file
#
# Each environment has it's own configuration options.  If you are only
# running in production, only the production block needs to be configured.
# Environment specific configuration options override the default ones.
#
# Note that this file needs to be a valid YAML file.
# DO NOT USE TABS! Use 2 spaces instead of tabs for identation.

production:
  email_delivery:
    delivery_method: :smtp
    smtp_settings:
      enable_starttls_auto:     true
      address:                  "smtp-mail.outlook.com"
      port:                     587
      authentication:           :plain
      user_name:                clo.devops.ci.report@outlook.jp
      password:                 P@ssw0rd1234

  # Configuration of RMagcik font.
  #
  # Redmine uses RMagcik in order to export gantt png.
  # You don't need this setting if you don't install RMagcik.
  #
  # In CJK (Chinese, Japanese and Korean),
  # in order to show CJK characters correctly,
  # you need to set this configuration.
  #
  # Because there is no standard font across platforms in CJK,
  # you need to set a font installed in your server.
  #
  # This setting is not necessary in non CJK.
  #
  # Examples for Japanese:
  #   Linux:
  #     rmagick_font_path: /usr/share/fonts/ipa-mincho/ipam.ttf
  #
  rmagick_font_path: /usr/share/fonts/ipa-pgothic/ipagp.ttf

__EOF__


echo cloud-init RHEL Redmine v2.5.x Settings Complete `date` >> ${LOGFILE}







echo cloud-init RHEL Ruby Gems Settings Start `date` >> ${LOGFILE}

/usr/bin/gem install bundler --no-rdoc --no-ri  >> ${LOGFILE}

cd /var/lib/redmine/
/usr/bin/bundle install --without development test >> ${LOGFILE}

/usr/bin/bundle exec rake generate_secret_token >> ${LOGFILE}
RAILS_ENV=production /usr/bin/bundle exec rake db:migrate >> ${LOGFILE}
RAILS_ENV=production /usr/bin/bundle exec rake redmine:load_default_data REDMINE_LANG=ja >> ${LOGFILE}

echo cloud-init RHEL Ruby Gems Settings Complete `date` >> ${LOGFILE}




echo cloud-init RHEL Redmine+Passenger Install Start `date` >> ${LOGFILE}

yum groupinstall -y "Development Tools" >> ${LOGFILE}

chown -R apache:apache /var/lib/redmine

cd /var/lib/redmine/
/usr/bin/gem install passenger --no-rdoc --no-ri >> ${LOGFILE}
/usr/bin/passenger-install-apache2-module --auto --languages ruby >> ${LOGFILE}

echo cloud-init RHEL Redmine+Passenger Install Complete `date` >> ${LOGFILE}


echo cloud-init RHEL Redmine+Passenger Settings Start `date` >> ${LOGFILE}

cat > /etc/httpd/conf.d/passenger.conf << __EOF__
# Passenger Settings
RackBaseURI /redmine

__EOF__

/usr/bin/passenger-install-apache2-module --snippet >> /etc/httpd/conf.d/passenger.conf

cat >> /etc/httpd/conf.d/passenger.conf << __EOF__
# Setting to delete the HTTP headers to add Passenger
Header always unset "X-Powered-By"
Header always unset "X-Rack-Cache"
Header always unset "X-Content-Digest"
Header always unset "X-Runtime"

# Added settings for tuning of Passenger
# Please see the Phusion Passenger users guide for more information.
# [http://www.modrails.com/documentation/Users%20guide%20Apache.html]
PassengerMaxPoolSize 20
PassengerMaxInstancesPerApp 4
PassengerPoolIdleTime 3600
PassengerHighPerformance on
PassengerStatThrottleRate 10
PassengerSpawnMethod smart
RailsAppSpawnerIdleTime 86400
PassengerMaxPreloaderIdleTime 0

__EOF__

/bin/egrep -v '^$|^#' /etc/httpd/conf.d/passenger.conf >> ${LOGFILE}

/bin/ln -s /var/lib/redmine/public /var/www/html/redmine >> ${LOGFILE}

/sbin/service httpd configtest >> ${LOGFILE}
/sbin/service httpd restart >> ${LOGFILE}

echo cloud-init RHEL Redmine+Passenger Settings Complete `date` >> ${LOGFILE}





echo cloud-init RHEL Jenkins Server Install Start `date` >> ${LOGFILE}

wget -t 5 -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo >> ${LOGFILE}
wget -t 5 -O /tmp/jenkins-ci.org.key http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key >> ${LOGFILE}
rpm --import /tmp/jenkins-ci.org.key >> ${LOGFILE}
yum clean all >> ${LOGFILE}
yum install -y ant java-1.7.0-openjdk java-1.7.0-openjdk-devel ipa-gothic-fonts ipa-pgothic-fonts vlgothic-fonts vlgothic-p-fonts vlgothic-fonts-common dejavu-sans-fonts fontconfig jenkins >> ${LOGFILE}

echo cloud-init RHEL Jenkins Server Install Complete `date` >> ${LOGFILE}


echo cloud-init RHEL Jenkins Server Setting Start `date` >> ${LOGFILE}

mkdir -p /var/lib/jenkins/.ssh

cat >> /var/lib/jenkins/.ssh/config << 'EOF';
Host *
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
EOF

cp -pr /home/ec2-user/.ssh/authorized_keys /var/lib/jenkins/.ssh/
chmod -R 600 /var/lib/jenkins/.ssh
chown -R jenkins:jenkins /var/lib/jenkins/.ssh

# Bash Configuration
cp -pr /etc/skel/.bash_profile /var/lib/jenkins/
cp -pr /etc/skel/.bashrc /var/lib/jenkins/
chown jenkins:jenkins /var/lib/jenkins/.bash_profile
chown jenkins:jenkins /var/lib/jenkins/.bashrc

# Sudo Configuration
sed -i 's/jenkins\:\/bin\/false/jenkins\:\/bin\/bash/g' /etc/passwd
sed -i 's/Defaults    requiretty/#Defaults    requiretty/g' /etc/sudoers
sed -i '/#Defaults    requiretty/a Defaults:jenkins !requiretty' /etc/sudoers
sed -i '/ec2-user/a jenkins         ALL=(ALL)       NOPASSWD: ALL' /etc/sudoers

# Jenkins Service SELinux Configuration
/usr/sbin/setsebool -P httpd_can_network_connect true
echo "/var/lib/jenkins/.+ unconfined_u:object_r:user_home_t:s0" >> /etc/selinux/targeted/contexts/files/file_contexts.homedirs
echo "/var/lib/jenkins/\.ssh(/.*)?      system_u:object_r:ssh_home_t:s0" >> /etc/selinux/targeted/contexts/files/file_contexts.homedirs
/sbin/restorecon -R -v /var/lib/jenkins

# Jenkins Service Configuration
sed -i 's/JENKINS_JAVA_OPTIONS/#JENKINS_JAVA_OPTIONS/g' /etc/sysconfig/jenkins
sed -i '/#JENKINS_JAVA_OPTIONS/a JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Duser.timezone=Asia/Tokyo -Xms4g -Xmx4g -XX:MaxPermSize=1024M"' /etc/sysconfig/jenkins
sed -i 's/JENKINS_ENABLE_ACCESS_LOG=\"no\"/JENKINS_ENABLE_ACCESS_LOG="yes"/g' /etc/sysconfig/jenkins
sed -i 's/JENKINS_ARGS/#JENKINS_ARGS/g' /etc/sysconfig/jenkins
sed -i '/#JENKINS_ARGS/a JENKINS_ARGS="--prefix=/jenkins"' /etc/sysconfig/jenkins

/sbin/service jenkins start >> ${LOGFILE}
/sbin/chkconfig jenkins on >> ${LOGFILE}

/bin/sleep 30
wget -t 5 -O /tmp/jenkins-cli.jar http://localhost:8080/jenkins/jnlpJars/jenkins-cli.jar >> ${LOGFILE}
wget -t 5 -O /tmp/jenkins-update-center.tmp http://updates.jenkins-ci.org/update-center.json >> ${LOGFILE}
tail -n +2 /tmp/jenkins-update-center.tmp | head -n -1 > /tmp/jenkins-update-center.json
curl -X POST -d @/tmp/jenkins-update-center.json http://localhost:8080/jenkins/updateCenter/byId/default/postBack >> ${LOGFILE}
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins list-plugins >> ${LOGFILE}
/sbin/service jenkins restart >> ${LOGFILE}

/bin/sleep 60
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins list-plugins >> ${LOGFILE}

# Default Plugin (Update)
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin mailer
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin ldap
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin credentials
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin ssh-credentials
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin ssh-slaves
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin subversion 
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin translation 

# New Plugin (Install)
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin ec2
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin s3
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin jenkins-cloudformation-plugin
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin docker-plugin
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin backup
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin timestamper
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin jobConfigHistory
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin changelog-history
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin backlog
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin monitoring
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin build-monitor-plugin
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin build-pipeline-plugin
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin build-name-setter
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin parameterized-trigger
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin metadata
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin terminal
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin cron_column
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin git
#java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin github
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin multiple-scms
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin checkstyle
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin findbugs
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin xunit
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin copyartifact
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin deploy
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin scp
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin publish-over-ssh
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin redmine
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin ircbot
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins install-plugin Email-ext

java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins list-plugins >> ${LOGFILE}
/sbin/service jenkins restart
/bin/sleep 30

echo cloud-init RHEL Jenkins Server Setting Complete `date` >> ${LOGFILE}




echo cloud-init RHEL SELinux Permissive Settings Start `date` >> ${LOGFILE}

/usr/sbin/getenforce >> ${LOGFILE}

/usr/sbin/setenforce Permissive >> ${LOGFILE}

/usr/sbin/getenforce >> ${LOGFILE}

/sbin/service auditd stop >> ${LOGFILE}

mv /var/log/audit/audit.log /var/log/audit/audit-old.log

/sbin/service auditd start >> ${LOGFILE}

echo cloud-init RHEL SELinux Permissive Settings Complete `date` >> ${LOGFILE}



echo cloud-init RHEL Service Restarting Start `date` >> ${LOGFILE}

/sbin/service jenkins restart >> ${LOGFILE}
/sbin/service httpd restart >> ${LOGFILE}
/sbin/service nginx restart >> ${LOGFILE}

echo cloud-init RHEL Service Restarting Complete `date` >> ${LOGFILE}






