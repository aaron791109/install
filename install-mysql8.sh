#!/bin/bash

# 確保腳本以 root 身份運行
if [ "$(id -u)" -ne 0 ]; then
    echo "請使用 root 權限運行此腳本 (使用 sudo)。"
    exit 1
fi

# 確定系統類型
if [ -f /etc/debian_version ]; then
    OS="debian"
elif [ -f /etc/redhat-release ]; then
    OS="redhat"
else
    echo "不支援的操作系統"
    exit 1
fi

# 安裝 MySQL 8
if [ "$OS" == "debian" ]; then
    echo "正在安裝 MySQL 8 (Ubuntu/Debian)..."
    apt update
    apt install -y wget lsb-release gnupg
    wget -c https://dev.mysql.com/get/mysql-apt-config_0.8.26-1_all.deb
    dpkg -i mysql-apt-config_0.8.26-1_all.deb
    apt update
    apt install -y mysql-server
elif [ "$OS" == "redhat" ]; then
    echo "正在安裝 MySQL 8 (CentOS/Rocky Linux)..."
    dnf install -y https://dev.mysql.com/get/mysql80-community-release-el8-1.noarch.rpm
    dnf install -y mysql-server
fi

# 創建 MySQL 日誌目錄
mkdir -p /data/mysql/logs /data/mysql/binlog /data/mysql/data 
chown -R mysql:mysql /data/mysql

# 啟動 MySQL 並設置開機自啟
systemctl enable --now mysqld

# 生成隨機 root 密碼
random_root_password=$(openssl rand -base64 12)

# 設置 MySQL root 密碼
echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '$random_root_password';" | mysql --connect-expired-password -u root

# 獲取系統記憶體的 80%
total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
buffer_pool_size=$((total_mem * 80 / 100 / 1024))M

# 優化 my.cnf 設置
cat > /etc/my.cnf <<EOF
[mysqld]
bind_address                    = 0.0.0.0
datadir=/data/mysql/data
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
default_authentication_plugin=mysql_native_password
skip_external_locking
skip_name_resolve


max_connections                 = 200
query_cache_size                = 0
max_allowed_packet              = 256M
max_connect_errors              = 1000000

# === InnoDB Settings ===
default_storage_engine          = InnoDB
innodb_buffer_pool_instances    = 4
innodb_buffer_pool_size         = ${buffer_pool_size}
innodb_file_per_table           = 1
innodb_flush_log_at_trx_commit  = 0
innodb_flush_method             = O_DIRECT
innodb_log_buffer_size          = 16M
innodb_log_file_size            = 256M
innodb_sort_buffer_size         = 4M
innodb_stats_on_metadata        = 0
innodb_read_io_threads          = 64
innodb_write_io_threads         = 64

# === Connection Settings ===
max_connections                 = 200
back_log                        = 512
thread_cache_size               = 100
thread_stack                    = 192K
interactive_timeout             = 180
wait_timeout                    = 180

# === Buffer Settings ===
join_buffer_size                = 4M
read_buffer_size                = 3M
read_rnd_buffer_size            = 4M
sort_buffer_size                = 4M

# === Table Settings ===
table_definition_cache          = 50000
table_open_cache                = 50000
open_files_limit                = 60000
max_heap_table_size             = 128M
tmp_table_size                  = 128M

# === Search Settings ===
ft_min_word_len                 = 3

mysqlx=0
general_log=0

# ===設置日誌文件位置 ===
log_error=/data/mysql/logs/mysql-error.log

# === 啟用 slow log ===
slow_query_log=1
slow_query_log_file=/data/mysql/logs/mysql-slow.log
long_query_time=5

# === 啟用 binlog ===
log_bin=/data/mysql/binlog
binlog_format=ROW
server_id=1
expire_logs_days=7
EOF


# 調整系統參數
cat >> /etc/sysctl.conf <<EOF
# === 系統級調整 ===
vm.swappiness = 1                # 降低 swap 使用優先級，保證內存資源最大化使用
net.core.somaxconn = 65535       # 最大連接隊列
net.core.netdev_max_backlog = 50000 # 提高網絡設備的最大排隊長度
net.ipv4.tcp_max_syn_backlog = 4096  # 增加 SYN 請求的隊列大小

# 增加最大文件描述符數量
fs.file-max = 2097152            # 增加操作系統最大文件描述符數量
fs.inotify.max_user_watches = 1048576 # 增加監視的最大數量
EOF

# 使 sysctl 配置生效
sysctl -p

# 調整文件描述符限制
cat >> /etc/security/limits.conf <<EOF
# MySQL 最大文件描述符限制
mysql soft nofile 65535
mysql hard nofile 65535
EOF

# 重新啟動 MySQL 使配置生效
systemctl restart mysqld

# 顯示安裝結果
echo "MySQL 8 安裝完成！"
echo "MySQL root 隨機密碼: $random_root_password"
echo "請記住此密碼，或手動修改為您想要的密碼。"
