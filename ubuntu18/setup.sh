#!/bin/bash

########
# 実行 #
########

# ubuntu更新
# 途中、インタラクティブに応答を要求される
# 放置したままssh接続が切れたら面倒なことになったので張り付き推奨
apt-get --with-new-pkgs upgrade -y

# セットアップに必要なパッケージをインストール
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" > /etc/apt/sources.list.d/pgdg_bionic.list'
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" > /etc/apt/sources.list.d/pgdg_xenial.list'
apt update
apt-get install -y \
  postgresql-$PG_VERSION \
  postgresql-$PG_VERSION-plv8 \
  pwgen \
  nodejs npm

echo 'ここでリブートしないと後でエラーになるよ'
pause

# ファイアウォール設定
ufw allow $SSH_PORT


# ホスト名設定
sed -i -e  "s/^.*127.0.0.1.*$/127.0.0.1 \$NEW_HOST_NAME/" /etc/hosts
hostname $NEW_HOST_NAME

# sshd設定
sed -i -e  "s/^.*\<Port\>.*$/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i -e  's/^.*\<PubkeyAuthentication\>.*$/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i -e  's/^.*\<PasswordAuthentication\>.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i -e  's/^.*\<ChallengeResponseAuthentication\>.*$/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sed -i -e  's/^.*\<UsePAM\>.*$/UsePAM no/' /etc/ssh/sshd_config
/etc/init.d/ssh restart

# 設定したポートでssh接続確認できたらデフォを塞ぐ
ufw default deny
ufw --force enable
ufw status verbose

# 管理ユーザー作成
adduser --disabled-password --gecos "" $ADMIN_USER
gpasswd -a $ADMIN_USER sudo
mkdir $SSH_DIR
wget $AUTH_KEY_URL -O $SSH_DIR/authorized_keys
chown -R $ADMIN_USER:$ADMIN_USER $SSH_DIR
chmod 700 $SSH_DIR
chmod 600 $SSH_DIR/authorized_keys

# Postgres
systemctl start postgresql.service
systemctl enable postgresql.service
/etc/init.d/postgresql restart

# Postgres (外部接続設定)
echo 'hostssl all all 0.0.0.0/0 md5' >> /etc/postgresql/$PG_VERSION/main/pg_hba.conf
sed -i -e  "s/.*\<listen_addresses\>.*/listen_addresses='*'/" /etc/postgresql/$PG_VERSION/main/postgresql.conf
sed -i -e  "s/.*\<port\>.*/port=$PG_PORT/" /etc/postgresql/$PG_VERSION/main/postgresql.conf
/etc/init.d/postgresql restart
ufw allow $PG_PORT
ufw --force enable
ufw status verbose
pwgen -s 16 1 > .pg_passwd
cat .pg_passwd
sudo -i -u postgres psql -c '\password postgres'

# Postgres (jsondb)
sudo -i -u postgres psql -c 'CREATE EXTENSION plv8;'
cat << EOT > pg_create_function_short_uid.plv8
create or replace function short_uid() returns text as \$\$
  const dic = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-'
  var uid = ""
  for (var i = 0; i < 23; i++) {
    uid += dic[Math.floor(Math.random()*dic.length)]
  }
  return uid;
\$\$ language plv8 immutable strict;
EOT
sudo -i -u postgres psql -f - < pg_create_function_short_uid.plv8
cat << EOT > pg_create_table_jsondb.sql
create table jsondb (
  id   char(23) primary key default short_uid(),
  type text  not null,
  data jsonb not null,
  created_at timestamptz not null default now()
);
EOT
sudo -i -u postgres psql -f - < pg_create_table_jsondb.sql


# nodejs
npm cache clean
npm install n -g
n stable
ln -sf /usr/local/bin/node /usr/bin/node
npm install yarn -g # apt-get upgradeからrebootしてないとここでエラーが出る
ufw allow 80
ufw allow 443
ufw --force enable
ufw status verbose
