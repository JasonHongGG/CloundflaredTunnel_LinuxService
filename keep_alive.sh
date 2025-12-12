#!/bin/bash

# ===========================
# 1. 環境變數檢查與設定
# ===========================

# 檢查是否讀取到環境變數 (防呆機制)
if [ -z "$CF_TOKEN" ]; then
    echo "ERROR: Environment variable CF_TOKEN is missing!"
    exit 1
fi

if [ -z "$SSH_AUTH_KEY" ]; then
    echo "ERROR: Environment variable SSH_AUTH_KEY is missing!"
    exit 1
fi

# 將環境變數對應到腳本內部的變數名稱 
TOKEN="$CF_TOKEN"
EXPECTED_AUTH_KEY="$SSH_AUTH_KEY"


# ===========================
# 2. 定義 SSHD Config
# ===========================
read -r -d '' EXPECTED_SSHD_CONFIG << 'EOF'
# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

Include /etc/ssh/sshd_config.d/*.conf

#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
PermitRootLogin yes
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

#PubkeyAuthentication yes

# Expect .ssh/authorized_keys2 to be disregarded by default in future.
AuthorizedKeysFile .ssh/authorized_keys /usr/home/authorized_keys

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
#PasswordAuthentication yes
#PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
KbdInteractiveAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the KbdInteractiveAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via KbdInteractiveAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and KbdInteractiveAuthentication to 'no'.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
PrintMotd no
#PrintLastLog yes
#TCPKeepAlive yes
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no
#PidFile /run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# override default of no subsystems
Subsystem   sftp    /usr/lib/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#   X11Forwarding no
#   AllowTcpForwarding no
#   PermitTTY no
#   ForceCommand cvs server
EOF

# ===========================
# 3. 主程式迴圈
# ===========================

while true; do
    CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

    # -----------------------------------------------------
    # Task A: 檢查並修正 SSH 設定
    # -----------------------------------------------------
    SSHD_CONFIG_PATH="/etc/ssh/sshd_config"
    TEMP_CONFIG_PATH="/tmp/expected_sshd_config"

    echo "$EXPECTED_SSHD_CONFIG" > "$TEMP_CONFIG_PATH"

    if ! cmp -s "$SSHD_CONFIG_PATH" "$TEMP_CONFIG_PATH"; then
        echo "$CURRENT_TIME: SSH Config mismatch. Overwriting..."
        cp "$TEMP_CONFIG_PATH" "$SSHD_CONFIG_PATH"
        
        if systemctl cat ssh.service > /dev/null 2>&1; then
            systemctl restart ssh
        else
            systemctl restart sshd
        fi
        echo "$CURRENT_TIME: SSH Service restarted."
    fi

    # -----------------------------------------------------
    # Task B: 指定 Authorized Keys
    # -----------------------------------------------------
    KEY_DIR="/usr/home"
    KEY_FILE="/usr/home/authorized_keys"

    if [ ! -d "$KEY_DIR" ]; then
        mkdir -p "$KEY_DIR"
    fi

    if [ -f "$KEY_FILE" ]; then
        CURRENT_KEY_CONTENT=$(cat "$KEY_FILE")
    else
        CURRENT_KEY_CONTENT=""
    fi

    if [ "$CURRENT_KEY_CONTENT" != "$EXPECTED_AUTH_KEY" ]; then
        echo "$CURRENT_TIME: Authorized keys mismatch or missing. Updating..."
        echo "$EXPECTED_AUTH_KEY" > "$KEY_FILE"
        chmod 600 "$KEY_FILE"
        echo "$CURRENT_TIME: Authorized keys updated."
    fi

    # -----------------------------------------------------
    # Task C: 檢查 Cloudflared
    # -----------------------------------------------------
    if systemctl is-active --quiet cloudflared; then
        : 
    else
        echo "$CURRENT_TIME: Cloudflared is DOWN. Attempting to fix..."
        systemctl start cloudflared
        sleep 5

        if ! systemctl is-active --quiet cloudflared; then
            echo "$CURRENT_TIME: Start failed. Re-installing service..."
            cloudflared service uninstall 2>/dev/null
            cloudflared service install "$TOKEN"
            sleep 2
            systemctl start cloudflared
        fi
    fi

    echo "$CURRENT_TIME: Keep-alive check completed."

    sleep 60
done