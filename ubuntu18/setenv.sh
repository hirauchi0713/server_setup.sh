cat << EOT >> .bashrc
############
# 初期設定 #
############

# ホスト名('_'は使えない。'-'なら可)
export NEW_HOST_NAME=template

# SSH
export SSH_PORT=22

# Admin User
export ADMIN_USER=hirauchi
export AUTH_KEY_URL=https://raw.githubusercontent.com/hirauchi0713/server_setup.sh/master/authorized_keys
export SSH_DIR=/home/\$ADMIN_USER/.ssh

# Postgres
export PG_VERSION=10
export PG_PORT=5432
EOT
