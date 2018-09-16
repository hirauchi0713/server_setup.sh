#!/bin/bash

# ubuntu更新
apt-get --with-new-pkgs upgrade -y

# sshd設定
sed -i -e  's/^.*\<Port\>.*$/Port 22/' /etc/ssh/sshd_config
sed -i -e  's/^.*\<PubkeyAuthentication\>.*$/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i -e  's/^.*\<PasswordAuthentication\>.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i -e  's/^.*\<ChallengeResponseAuthentication\>.*$/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sed -i -e  's/^.*\<UsePAM\>.*$/UsePAM no/' /etc/ssh/sshd_config
/etc/init.d/ssh restart

# ファイアウォール設定
ufw allow 22
ufw allow 80
ufw allow 443
ufw default deny
ufw --force enable
ufw status verbose

# ホスト名設定
NEW_HOST_NAME=template
sed -i -e  "s/^.*127.0.0.1.*$/127.0.0.1 $NEW_HOST_NAME/" /etc/hosts
hostname $NEW_HOST_NAME

# nodejs
apt-get install -y nodejs npm
npm cache clean
npm install n -g
n stable
ln -sf /usr/local/bin/node /usr/bin/node
npm install yarn -g

# 管理ユーザー作成
ADMIN_USER=hirauchi
AUTH_KEY_URL=https://github.com/hirauchi0713.keys
adduser --disabled-password --gecos "" $ADMIN_USER
gpasswd -a $ADMIN_USER sudo
mkdir /home/$ADMIN_USER/.ssh
wget $AUTH_KEY_URL -O /home/$ADMIN_USER/.ssh/authorized_keys
chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.ssh
chmod 700 /home/$ADMIN_USER/.ssh
chmod 600 /home/$ADMIN_USER/.ssh/authorized_keys

