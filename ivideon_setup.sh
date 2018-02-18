set -v
set -e

function die {
  RED='\033[0;31m'
  NC='\033[0m'
  echo -e "${RED}${1}${NC}"
  exit 1
}

umask 0077
useradd -m videouser
chmod -R go= /home/videouser
chmod -R u+rwx /home/videouser
apt-get update
APT_LISTCHANGES_FRONTEND=none apt-get -y upgrade
apt-get -y install openvpn sudo chpasswd

apt-get install xserver-xorg xserver-xorg-core xfonts-base xinit --no-install-recommends
apt-get install libgl1-mesa-dri x11-xserver-utils gnome-session gnome-shell gnome-themes gnome-terminal gnome-control-center nautilus gnome-icon-theme --no-install-recommends
apt-get install gdm3 --no-install-recommends

wget http://packages.ivideon.com/ubuntu/keys/ivideon.list -O /etc/apt/sources.list.d/ivideon.list
wget -O - http://packages.ivideon.com/ubuntu/keys/ivideon.key | sudo apt-key add -
apt-get install ivideon-video-server

NEW_USER=videouser
echo 'Set password for' $NEW_USER
IFS= read -s  -r -p Password: USR_PWD
echo "${NEW_USER}:${USR_PWD}" | chpasswd || die "failed to set password"
unset USR_PWD

OVPN_CLIENT_CONF=/etc/openvpn/client.conf
if [ ! -e  $OVPN_CLIENT_CONF ]; then
  echo "Copy OpenVPN client config to: $OVPN_CLIENT_CONF"
  echo "Hit any key when done"
  read
  if [ ! -e  $OVPN_CLIENT_CONF ]; then die "file $OVPN_CLIENT_CONF does not exist"; fi
fi

chmod u=rw /etc/openvpn/client.conf 
chmod og= /etc/openvpn/client.conf 

echo "Starting OpenVPN service client"
systemctl start openvpn@client.service || die "failed starting OpenVPN, use 'systemctl -l status openvpn@client.service' to see more details"

echo "Enabling OpenVPN for startup"
systemctl enable openvpn@client.service || die "failed to enable OpenVPN for startup, use 'systemctl -l status openvpn@client.service' to see more details"

su videouser
umask 0077
cd ~
mkdir Ivideon
mkdir -p ~/.config/systemd/user
cat <<EOF > ~/.config/systemd/user/ivideon-server.service
[Unit]
Description=Ivideon Videoserverd

[Service]
Type=forking
PIDFile=/home/videouser/.IvideonServer/videoserverd.pid
ExecStart=/opt/ivideon/ivideon-server/auto_respawn -d -w /home/videouser/.IvideonServer -u videouser -p /home/videouser/.IvideonServer/videoserverd.pid /opt/ivideon/ivideon-server/videoserver -c /home/videouser/.IvideonServer/videoserverd.config
ExecStop=/opt/ivideon/ivideon-server/auto_respawn -K 5 -p $MAINPID

[Install]
WantedBy=default.target
EOF

echo "Enabling Ivideon Server for startup"
systemctl --user enable ivideon-server || die "failed to enable Ivideon Server for startup"
