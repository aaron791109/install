#!/bin/bash

# 優化 TCP 和網路設置
echo "正在優化 TCP 和網路設置..."

# 增加最大文件描述符數量
echo "fs.file-max = 2097152" | tee -a /etc/sysctl.conf

# 增加 TCP 連接數量
echo "net.core.somaxconn = 65535" | tee -a /etc/sysctl.conf

# 增加 TCP 接收和發送緩衝區大小
echo "net.core.rmem_max = 16777216" | tee -a /etc/sysctl.conf
echo "net.core.rmem_default = 1048576" | tee -a /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" | tee -a /etc/sysctl.conf
echo "net.core.wmem_default = 1048576" | tee -a /etc/sysctl.conf

# 增加 TCP 同步連接排隊的大小
echo "net.ipv4.tcp_max_syn_backlog = 4096" | tee -a /etc/sysctl.conf

# 增加 TCP 自動調整接收和發送緩衝區大小範圍
echo "net.ipv4.tcp_rmem = 4096 87380 16777216" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 65536 16777216" | tee -a /etc/sysctl.conf

# 開啟 TCP Fast Open
echo "net.ipv4.tcp_fastopen = 3" | tee -a /etc/sysctl.conf

# 增加內核的 TCP 連接追蹤表大小
echo "net.netfilter.nf_conntrack_max = 1048576" | tee -a /etc/sysctl.conf
echo "net.netfilter.nf_conntrack_tcp_timeout_established = 3600" | tee -a /etc/sysctl.conf
echo "net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 60" | tee -a /etc/sysctl.conf
echo "net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 30" | tee -a /etc/sysctl.conf
echo "net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120" | tee -a /etc/sysctl.conf
echo "net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60" | tee -a /etc/sysctl.conf

# 增加 conntrack 表掃描間隔
echo "net.netfilter.nf_conntrack_cleanup_interval = 30" | tee -a /etc/sysctl.conf

# 調整 conntrack hash 桶大小
echo "net.netfilter.nf_conntrack_buckets = 262144" | tee -a /etc/sysctl.conf

# 增加網路緩衝區
echo "net.core.netdev_max_backlog = 50000" | tee -a /etc/sysctl.conf

# 增加網路選項的最大內存緩衝區大小
echo "net.core.optmem_max = 25165824" | tee -a /etc/sysctl.conf

# 關閉 TCP 延遲確認 (如果需要)
echo "net.ipv4.tcp_delack_min = 100" | tee -a /etc/sysctl.conf

# 增加最大開放文件描述符數量
echo "* soft nofile 1048576" | tee -a /etc/security/limits.conf
echo "* hard nofile 1048576" | tee -a /etc/security/limits.conf

# 增加 vm 設置
echo "vm.swappiness = 1" | tee -a /etc/sysctl.conf
echo "vm.dirty_ratio = 40" | tee -a /etc/sysctl.conf
echo "vm.dirty_background_ratio = 10" | tee -a /etc/sysctl.conf

# 重新加載 sysctl 配置
echo "重新加載 sysctl 配置..."
sysctl -p

# 結束
echo "系統優化完成！"
