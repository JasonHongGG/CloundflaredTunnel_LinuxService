# CloundflaredTunnel_LinuxService


- clondflared.service
    
    ```bash
    /etc/systemd/system/
    ```
    
- keep_alive
    ```
    /usr/libx64
    ```
- service.env
    ```
    /usr/home/
    ```

- SSH 多把公鑰（可選）

    `SSH_AUTH_KEY` 支援用 `|` 分隔多把公鑰，腳本會自動轉成多行寫入 `/usr/home/authorized_keys`。

    範例：

    ```dotenv
    SSH_AUTH_KEY=ssh-ed25519 AAAA... user1@pc|ssh-ed25519 BBBB... user2@pc
    ```

- 相關指令
    
    ```bash
    # 重新讀取設定
    sudo systemctl daemon-reload
    
    # 啟動服務
    sudo systemctl start {服務名稱}
    
    # 停止服務
    sudo systemctl stop {服務名稱}
    
    # 重新啟動服務
    sudo systemctl restart {服務名稱}
    
    # 設定開機自動啟動
    sudo systemctl enable {服務名稱}
    
    # 查看監控日誌
    journalctl -u {服務名稱} -f
    
    # 查看所有正在執行的系統服務
    systemctl list-units --type=service --state=running
    
    # 查看所有系統服務
    systemctl list-units --type=service --all
    ```

- 紀錄
    ```
    UsePAM yes
    PermitRootLogin yes
    AuthorizedKeysFile .ssh/authorized_keys /usr/home/authorized_keys
    ```
