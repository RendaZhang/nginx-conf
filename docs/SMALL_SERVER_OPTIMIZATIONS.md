<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [针对小内存服务器的优化和增强建议](#%E9%92%88%E5%AF%B9%E5%B0%8F%E5%86%85%E5%AD%98%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%9A%84%E4%BC%98%E5%8C%96%E5%92%8C%E5%A2%9E%E5%BC%BA%E5%BB%BA%E8%AE%AE)
  - [简介](#%E7%AE%80%E4%BB%8B)
  - [速率限制:](#%E9%80%9F%E7%8E%87%E9%99%90%E5%88%B6)
  - [使用轻量级 WSGI 服务器](#%E4%BD%BF%E7%94%A8%E8%BD%BB%E9%87%8F%E7%BA%A7-wsgi-%E6%9C%8D%E5%8A%A1%E5%99%A8)
  - [后端服务相关的调整建议](#%E5%90%8E%E7%AB%AF%E6%9C%8D%E5%8A%A1%E7%9B%B8%E5%85%B3%E7%9A%84%E8%B0%83%E6%95%B4%E5%BB%BA%E8%AE%AE)
  - [防火墙增强:](#%E9%98%B2%E7%81%AB%E5%A2%99%E5%A2%9E%E5%BC%BA)
  - [日志监控:](#%E6%97%A5%E5%BF%97%E7%9B%91%E6%8E%A7)
    - [简单的轻量级监控工具](#%E7%AE%80%E5%8D%95%E7%9A%84%E8%BD%BB%E9%87%8F%E7%BA%A7%E7%9B%91%E6%8E%A7%E5%B7%A5%E5%85%B7)
    - [功能全面的轻量级监控工具](#%E5%8A%9F%E8%83%BD%E5%85%A8%E9%9D%A2%E7%9A%84%E8%BD%BB%E9%87%8F%E7%BA%A7%E7%9B%91%E6%8E%A7%E5%B7%A5%E5%85%B7)
  - [设置交换空间（如果尚未设置）](#%E8%AE%BE%E7%BD%AE%E4%BA%A4%E6%8D%A2%E7%A9%BA%E9%97%B4%E5%A6%82%E6%9E%9C%E5%B0%9A%E6%9C%AA%E8%AE%BE%E7%BD%AE)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 针对小内存服务器的优化和增强建议

## 简介

本文是针对 **小内存** 服务器所提供的建议和优化，并且以 CentOS 7 系统作为例子。

## 速率限制:

```nginx
# 在 nginx.conf 的 http 块添加
limit_req_zone $binary_remote_addr zone=flask_limit:10m rate=5r/s;

# 在 location /cloudchat/ 添加
limit_req zone=flask_limit burst=10 nodelay;
```

## 使用轻量级 WSGI 服务器

- 使用 Gunicorn + Gevent 作为 WSGI 服务器

部署示例：
```bash
pip install gunicorn
gunicorn -w 2 -k gevent your_app:app
```

## 后端服务相关的调整建议

- 限制对话历史长度
- 定期清理旧会话

具体可以参考 Python 后端项目的文档：[轻量级会话存储方案（针对小内存服务器）](https://github.com/RendaZhang/python-cloud-chat/blob/master/docs/lightweight_backend_development.md#%E8%BD%BB%E9%87%8F%E7%BA%A7%E4%BC%9A%E8%AF%9D%E5%AD%98%E5%82%A8%E6%96%B9%E6%A1%88%E9%92%88%E5%AF%B9%E5%B0%8F%E5%86%85%E5%AD%98%E6%9C%8D%E5%8A%A1%E5%99%A8)

## 防火墙增强:

```bash
# 安装 firewalld
sudo yum install firewalld
sudo systemctl start firewalld

# 开放必要端口
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

## 日志监控:

### 简单的轻量级监控工具

安装 htop 步骤：

```bash
# Enable the EPEL repository:
sudo yum install epel-release
# Install htop:
sudo yum install htop
# Run htop:
htop
```

使用 htop 简单地定期去手动检查内存使用情况。

### 功能全面的轻量级监控工具

安装 glances 步骤：

```bash
# Enable the EPEL repository (if not already enabled):
sudo yum install epel-release
# Install glances:
sudo yum install glances
# Run glances:
glances
```

使用 glances 可以实现 Web-based 界面的远程监控，支持提醒功能和插件扩展。

## 设置交换空间（如果尚未设置）

```bash
# Creates a 1GB file named /swapfile using fallocate:
sudo fallocate -l 1G /swapfile

# Set Permissions: only the root user can read and write to the swap file.
sudo chmod 600 /swapfile

# Initializes the file as swap space:
sudo mkswap /swapfile

# Activates the swap file
sudo swapon /swapfile

# Make the Swap File Permanent
# Open /etc/fstab for editing:
sudo vi /etc/fstab
# Add the following line at the end of the file:
/swapfile swap swap defaults 0 0
# Save and exit the editor.

# Verify the Swap Space
# Check if the swap space is active using:
sudo swapon --show
# View the total memory and swap space with:
free -h

# Adjusting Swapiness
# Check the current swappiness value (Default is 60):
cat /proc/sys/vm/swappiness
# Set a lower swappiness value for better performance on small-memory servers:
sudo sysctl vm.swappiness=10
# Make the change permanent by adding the following line to /etc/sysctl.conf:
vm.swappiness=10
```
