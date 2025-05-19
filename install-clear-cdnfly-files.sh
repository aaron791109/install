#!/bin/bash
sudo tee /opt/clear_cdnfly_node_logs.sh > /dev/null <<'EOF'
#!/bin/bash
# 設定目標目錄
LOG_DIR="/var/log/cdnfly/"

# 使用 ls 獲取所有文件（排除目錄）
for file_a in $(ls -p "${LOG_DIR}" | grep -v /); do
    if [ -f "${LOG_DIR}/${file_a}" ]; then
        truncate -s 0 "${LOG_DIR}/${file_a}"
        #echo "Cleared ${LOG_DIR}/${file_a}"
    fi
done


SEC_LOG_DIR="/usr/local/openresty/nginx/logs/"

# 使用 ls 獲取所有 .log 文件
for file_b in $(ls "${SEC_LOG_DIR}"/*.log 2>/dev/null); do
    if [ -f "${file_b}" ]; then
        truncate -s 0 "${file_b}"
        #echo "Cleared $file_b"
    fi
done

truncate -s 0 /var/log/cdnfly.log
rm -rf /var/cache/yum/*
EOF

chmod +x /opt/clear_cdnfly_node_logs.sh

echo -e "0 0 * * * /bin/bash /opt/clear_cdnfly_node_logs.sh" >> /var/spool/cron/root