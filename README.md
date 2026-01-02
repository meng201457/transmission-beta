arm64/transmission-docker-beta/peerbanhelper

| 环境变量 | 功能说明 | 默认值 |
| :--- | :--- | :--- |
| `TRANSMISSION_WEB_HOME` | 自定义Webui路径指定
| `TRANSMISSION_WEBUI_USER` | Web 管理界面的登录用户名 | `admin` |
| `TRANSMISSION_WEBUI_PASS` | Web 管理界面的登录密码 | `admin123` |
| `PUID` / `PGID` | 运行进程的用户/组 ID (用于权限管理) | `1000` / `1000` |
| `TZ` | 容器时区 | `Asia/Shanghai` |
| `TRANSMISSION_HOME` | 内部配置文件存储路径 | `/config` |
```bash
version: '3.8'
services:
  transmission-beta:
    image: ghcr.io/meng201457/transmission-beta:latest
    container_name: transmission-beta
    restart: unless-stopped
    environment:
      - TRANSMISSION_WEBUI_USER=admin      # 你的用户名
      - TRANSMISSION_WEBUI_PASS=admin123   # 你的密码
      - TZ=Asia/Shanghai
    volumes:
      - ./config:/config                   # 配置挂载
      - ./downloads:/downloads             # 下载路径挂载
    ports:
      - "9091:9091"                        # Web UI 访问端口
      - "51413:51413"                      # BT 传输端口 (TCP)
      - "51413:51413/udp"                  # BT 传输端口 (UDP)
