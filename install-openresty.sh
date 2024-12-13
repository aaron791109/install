#!/bin/bash
sudo apt-get -y install --no-install-recommends wget gnupg ca-certificates lsb-release
wget -O - https://openresty.org/package/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/openresty.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openresty.gpg] http://openresty.org/package/ubuntu $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/openresty.list > /dev/null
sudo apt-get update
sudo apt-get -y install openresty -y
sudo groupadd openresty
sudo useradd -r -s /sbin/nologin -g openresty openresty
mkdir /usr/local/openresty/nginx/conf/vhost /var/log/openresty /var/cache/openresty
chown -R openresty:openresty /var/log/openresty /var/cache/openresty
systemctl enable openresty
systemctl start openresty
systemctl status openresty

cat << "EOF" > /usr/local/openresty/nginx/conf/nginx.conf
user  openresty;
worker_processes auto;

error_log  /var/log/openresty/error.log warn;
#pid        /var/run/openresty.pid;

# Maximum number of open file descriptors per process
# should be > worker_connections
worker_rlimit_nofile 65535;

events {
    # Use epoll on Linux 2.6+
    use epoll;
    # Max number of simultaneous connections per worker process
    worker_connections 65534;
    # Accept all new connections at one time
    multi_accept on;
}

http {
    include       /usr/local/openresty/nginx/conf/mime.types;
    default_type  application/octet-stream;
    #charset   utf-8;

    server_names_hash_bucket_size 128;
    client_header_buffer_size 2k;
    large_client_header_buffers 4 4k;
    server_tokens off;
    #Enables or disables emitting nginx version on error pages and in the “Server” response header field.s

    ## trust private ip range
    set_real_ip_from 10.0.0.0/8;
    set_real_ip_from 172.16.0.0/12;
    set_real_ip_from 192.168.0.0/16;
    # Specify the header used to get the real client IP
    real_ip_header X-Forwarded-For;
    # Enable recursive IP address extraction
    real_ip_recursive on;

    ## Get X-Forwarded-For Most Left
    map $http_x_forwarded_for $firstXFF {
            ""    $remote_addr;
            ~^(?<bb>[^,]*) $bb;
    }

    log_format main escape=json '{'
      '"msec": "$msec", ' # request unixtime in seconds with a milliseconds resolution
      '"connection": "$connection", ' # connection serial number
      '"connection_requests": "$connection_requests", ' # number of requests made in connection
      '"pid": "$pid", ' # process pid
      '"request_id": "$request_id", ' # the unique request id
      '"request_length": "$request_length", ' # request length (including headers and body)
      '"remote_addr": "$remote_addr", ' # client IP
      '"remote_user": "$remote_user", ' # client HTTP username
      '"remote_port": "$remote_port", ' # client port
      '"time_local": "$time_local", '
      '"time_iso8601": "$time_iso8601", ' # local time in the ISO 8601 standard format
      '"request": "$request", ' # full path no arguments if the request
      '"request_uri": "$request_uri", ' # full path and arguments if the request
      '"args": "$args", ' # args
      '"status": "$status", ' # response status code
      '"body_bytes_sent": "$body_bytes_sent", ' # the number of body bytes exclude headers sent to a client
      '"bytes_sent": "$bytes_sent", ' # the number of bytes sent to a client
      '"http_referer": "$http_referer", ' # HTTP referer
      '"http_user_agent": "$http_user_agent", ' # user agent
      '"http_x_forwarded_for": "$firstXFF", ' # http_x_forwarded_for
      '"http_host": "$http_host", ' # the request Host: header
      '"server_name": "$server_name", ' # the name of the vhost serving the request
      '"request_time": "$request_time", ' # request processing time in seconds with msec resolution
      '"upstream": "$upstream_addr", ' # upstream backend server for proxied requests
      '"upstream_connect_time": "$upstream_connect_time", ' # upstream handshake time incl. TLS
      '"upstream_header_time": "$upstream_header_time", ' # time spent receiving upstream headers
      '"upstream_response_time": "$upstream_response_time", ' # time spend receiving upstream body
      '"upstream_response_length": "$upstream_response_length", ' # upstream response length
      '"upstream_cache_status": "$upstream_cache_status", ' # cache HIT/MISS where applicable
      '"ssl_protocol": "$ssl_protocol", ' # TLS protocol
      '"ssl_cipher": "$ssl_cipher", ' # TLS cipher
      '"scheme": "$scheme", ' # http or https
      '"request_method": "$request_method", ' # request method
      '"server_protocol": "$server_protocol", ' # request protocol, like HTTP/1.1 or HTTP/2.0
      '"pipe": "$pipe", ' # "p" if request was pipelined, "." otherwise
      '"gzip_ratio": "$gzip_ratio", '
      '"http_cf_ray": "$http_cf_ray"'
      '}';

    access_log  /var/log/openresty/access.log main;

    sendfile   on;
    tcp_nopush on;
    client_max_body_size 40M;
    keepalive_timeout  65;

    gzip off;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_http_version 1.0;
    gzip_comp_level 2;
    gzip_types text/plain text/css application/json application/x-javascript application/xml application/javascript text/javascript application/x-httpd-php image/svg+xml;
    gzip_vary on;
    proxy_cache_path /var/cache/openresty levels=1:2 keys_zone=static-cache:10m max_size=1024m inactive=24h use_temp_path=off;

    include /usr/local/openresty/nginx/conf/vhost/*.conf;
}
EOF


cat << EOF >> /etc/security/limits.conf
openresty   soft  nofile  65535
openresty   hard  nofile  65535
EOF

cat << EOF >> /etc/sysctl.conf
fs.file-max = 2097152
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.icmp_echo_ignore_all = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.tcp_rmem = 4096 87380 6291456
net.ipv4.tcp_wmem = 4096 65536 6291456
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
fs.epoll.max_user_watches = 524288
EOF
sysctl -p
