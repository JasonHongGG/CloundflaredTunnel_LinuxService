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

- 相關指令
    
    ```bash
    # 重新讀取設定
    sudo systemctl daemon-reload
    
    # 啟動服務
    sudo systemctl start {服務名稱}
    
    # 停止服務
    sudo systemctl stop{服務名稱}
    
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