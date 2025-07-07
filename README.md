# Nginx Configuration for rendazhang.com

本仓库存储了 [www.rendazhang.com](https://www.rendazhang.com) 网站的 Nginx 服务器配置。这些配置文件针对生产环境优化，支持 HTTPS、反向代理和安全防护措施。

## 🚀 服务器环境信息

- **服务器位置**: 香港
- **操作系统**: CentOS 7
- **服务器配置**:
  - 2 vCPUs
  - 1 GB RAM
  - 40 GB SSD
- **Web 服务器**: Nginx
- **后端服务**: Python Flask (运行在 `127.0.0.1:8080`)
- **前端技术**: 原生 HTML, CSS, JavaScript

## 📁 配置文件说明

| 文件 | 作用 |
|------|------|
| `nginx.conf` | 主配置文件 |
| `fastcgi.conf` | FastCGI 相关配置 |
| `fastcgi_params` | FastCGI 参数设置 |
| `scgi_params` | SCGI 协议参数 |
| `uwsgi_params` | uWSGI 协议参数 |
| `mime.types` | MIME 类型映射 |

> ⚠ **注意**: 证书文件(`cert/`, `ssl/`)和日志文件(`logs/`)等敏感/临时文件已通过 `.gitignore` 排除

## 🧭 关键配置功能 (`nginx.conf`)

- **HTTP → HTTPS 重定向**:
  - 所有 HTTP 请求 (端口 80) 自动重定向到 HTTPS (端口 443)
- **SSL 设置**:
  - 证书: `cert/rendazhang.com.pem`
  - 私钥: `cert/rendazhang.com.key`
  - 支持 `TLSv1.2` 和 `TLSv1.3`
- **网站根目录**: `/usr/local/nginx/RendaZhang`
- **反向代理**:
  - `/cloudchat/` 路径代理到 `http://127.0.0.1:8080/`
  - 仅当 `Referer` 头以 `https://rendazhang.com` 开头时才生效
- **安全措施**:
  - 阻止访问 `.git`, `.gitignore`, `package.json` 等敏感文件
- **自定义错误页面**:
  - `404.html`, `50x.html`

## 🧩 网站功能概述

- 🎵 背景音乐播放器开关
- 🤖 AI 聊天机器人 (基础版和 GPT 增强版)
- 🖼️ 文本到图像生成功能
- 📄 简历下载 (PDF 格式)
- 🌏 多语言支持 (英文 + 中文)
- ✉️ 联系表单 (通过 Formspree) 及邮件/电话支持
- 💰 捐赠支持:
  - 微信支付
  - 支付宝
  - PayPal
- 📱 响应式设计 (移动端和桌面端)
- 💤 图片懒加载

## 🚚 迁移指南

### 目标服务器要求
1. **操作系统**: CentOS 7 或更高版本
2. **Nginx 版本**: 1.18.0+ (与当前生产环境匹配)
3. **依赖组件**:
   - Python 3.6+
   - Flask 框架
   - 开放的端口: 80 (HTTP), 443 (HTTPS)
4. **资源规格**:
   - 最低: 1 vCPU, 1GB RAM, 20GB 存储
   - 推荐: 2 vCPU, 2GB RAM, 40GB 存储 (与原环境相同)

### 迁移步骤

```bash
# 1. 克隆配置仓库
git clone git@gitee.com:yourname/nginx-conf.git

# 2. 复制配置文件 (保留文件权限)
sudo cp -p nginx-conf/* /usr/local/nginx/conf/

# 3. 安装证书 (手动操作，不上传至 Git)
# 将证书文件放入 /usr/local/nginx/conf/cert/
# 确保文件名与配置中一致: 
#   - rendazhang.com.pem
#   - rendazhang.com.key

# 4. 部署静态网站
git clone git@gitee.com:yourname/rendazhang.git /usr/local/nginx/RendaZhang

# 5. 部署 Flask 后端 (需单独准备)
#   假设 Flask 应用部署在 /home/ubuntu/flask-app
#   使用 systemd 管理服务:
sudo tee /etc/systemd/system/renda-flask.service > /dev/null <<EOF
[Unit]
Description=Renda Zhang Flask App
After=network.target

[Service]
User=root
WorkingDirectory=/home/ubuntu/flask-app
ExecStart=/usr/bin/python3 app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start renda-flask
sudo systemctl enable renda-flask

# 6. 测试并重启 Nginx
sudo nginx -t  # 验证配置
sudo systemctl restart nginx
```

### 验证迁移
1. 访问 `http://服务器IP` 应自动跳转至 `https://服务器IP`
2. 检查各功能页面:
   - 主页面: `/index.html`
   - 聊天功能: `/chat.html`
   - 图像生成: `/image_generation.html`
3. 验证后端服务:
   ```bash
   curl -X POST https://服务器IP/cloudchat/chat -d "message=test"
   ```

## 🔒 证书更新指南
证书需定期手动更新（建议使用 Certbot 自动化）：
```bash
# 安装 Certbot
sudo yum install epel-release
sudo yum install certbot python2-certbot-nginx

# 申请证书 (首次)
sudo certbot --nginx -d rendazhang.com -d www.rendazhang.com

# 设置自动续期 (每月检查)
sudo crontab -e
# 添加以下内容:
0 0 1 * * /usr/bin/certbot renew --quiet
```

## ✅ 改进建议
1. **速率限制**:
   ```nginx
   # 在 nginx.conf 的 http 块添加
   limit_req_zone $binary_remote_addr zone=flask_limit:10m rate=5r/s;

   # 在 location /cloudchat/ 添加
   limit_req zone=flask_limit burst=10 nodelay;
   ```
2. **防火墙增强**:
   ```bash
   # 安装 firewalld
   sudo yum install firewalld
   sudo systemctl start firewalld
   
   # 开放必要端口
   sudo firewall-cmd --permanent --add-service=http
   sudo firewall-cmd --permanent --add-service=https
   sudo firewall-cmd --reload
   ```
3. **日志监控**:
   ```bash
   # 安装 logwatch
   sudo yum install logwatch
   sudo cp /usr/share/logwatch/default.conf/logwatch.conf /etc/logwatch/conf/
   ```

## 🛠️ 故障排查
```bash
# 检查 Nginx 错误
tail -f /usr/local/nginx/logs/error.log

# 检查 Flask 日志
journalctl -u renda-flask -f

# 测试 SSL 配置
openssl s_client -connect www.rendazhang.com:443 -servername www.rendazhang.com
```

## 📎 相关资源
- 网站: [https://www.rendazhang.com](https://www.rendazhang.com)
- 前端仓库: [gitee.com/yourname/rendazhang](https://gitee.com/yourname/rendazhang)
- Flask 文档: [flask.palletsprojects.com](https://flask.palletsprojects.com/)

> **重要提示**: 每次修改配置后，请运行 `nginx -t` 验证配置有效性后再重启服务