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
mkdir -p /data/mysql/logs /data/mysql/binlog
chown -R mysql:mysql /data/mysql

# 啟動 MySQL 並設置開機自啟
systemctl enable --now mysqld

# 生成隨機 root 密碼
random_root_password=$(openssl rand -base64 12)

# 設置 MySQL root 密碼
echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '$random_root_password';" | mysql --connect-expired-password -u root

# 優化 my.cnf 設置
cat > /etc/my.cnf <<EOF
[mysqld]
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
innodb_buffer_pool_size=1G
innodb_log_file_size=256M
max_connections=500
query_cache_size=0
skip-name-resolve

# 關閉 MySQL X Plugin
default_authentication_plugin=mysql_native_password
mysqlx=0

# 關閉 general log
general_log=0

# 設置日誌文件位置
log_error=/data/mysql/logs/mysql-error.log

# 啟用 slow log
slow_query_log=1
slow_query_log_file=/data/mysql/logs/mysql-slow.log
long_query_time=1

# 啟用 binlog
log_bin=/data/mysql/binlog
binlog_format=ROW
server_id=1
expire_logs_days=7
EOF

# 重新啟動 MySQL 使配置生效
systemctl restart mysqld

# 顯示安裝結果
echo "MySQL 8 安裝完成！"
echo "MySQL root 隨機密碼: $random_root_password"
echo "請記住此密碼，或手動修改為您想要的密碼。"
