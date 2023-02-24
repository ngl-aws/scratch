#!/bin/bash -v

apt-get install -q -y python-setuptools wget tmux unzip tar curl sed
apt-get -q -y install dpkg-dev

if ((uname -a | grep x86 1>/dev/null) && (cat /etc/os-release | grep 22.04 1>/dev/null)); then
  rm -f /tmp/nice-dcv-ubuntu1804-x86_64.tgz
  wget https://d1uj6qtbmh3dt5.cloudfront.net/nice-dcv-ubuntu2204-x86_64.tgz
  tar -xvzf nice-dcv-ubuntu*.tgz && cd nice-dcv-*-x86_64
elif ((uname -a | grep x86 1>/dev/null) && (cat /etc/os-release | grep 18.04 1>/dev/null)); then
  rm -f /tmp/nice-dcv-ubuntu1804-x86_64.tgz
  wget https://d1uj6qtbmh3dt5.cloudfront.net/nice-dcv-ubuntu1804-x86_64.tgz
  tar -xvzf nice-dcv-ubuntu*.tgz && cd nice-dcv-*-x86_64
elif (cat /etc/os-release | grep 18.04 1>/dev/null); then
  rm -f /tmp/nice-dcv-ubuntu1804-aarch64.tgz
  wget https://d1uj6qtbmh3dt5.cloudfront.net/nice-dcv-ubuntu1804-aarch64.tgz
  tar -xvzf nice-dcv-ubuntu*.tgz && cd nice-dcv-*-aarch64
else
  rm -f /tmp/nice-dcv-ubuntu2004-x86_64.tgz
  wget https://d1uj6qtbmh3dt5.cloudfront.net/nice-dcv-ubuntu2004-x86_64.tgz
  tar -xvzf nice-dcv-ubuntu*.tgz && cd nice-dcv-*-x86_64
fi
sudo apt-get install -y ./nice-dcv-server_*.deb
sudo apt-get install -y ./nice-dcv-web-viewer_*.deb
usermod -aG video dcv
sudo apt-get install -y ./nice-xdcv_*.deb

#if [ ${ROSVERSION} == "ROS1Melodic" ] || [ ${ROSVERSION} == "NoROSUbuntu1804" ]; then
## get_dcv_pkg
#wget https://d1uj6qtbmh3dt5.cloudfront.net/2022.2/Servers/nice-dcv-2022.2-14521-ubuntu1804-x86_64.tgz
#tar -xvzf nice-dcv-2022.2-14521-ubuntu1804-x86_64.tgz && rm nice-dcv-2022.2-14521-ubuntu1804-x86_64.tgz
#
## install_dcv
#echo Installing DCV for Ubuntu 18.04
#cd nice-dcv-2022.2-14521-ubuntu1804-x86_64 && \
#DEBIAN_FRONTEND=noninteractive apt-get install -y \
#./nice-dcv-server_2022.2.14521-1_amd64.ubuntu1804.deb \
#./nice-xdcv_2022.2.519-1_amd64.ubuntu1804.deb
#
#elif [ ${ROSVERSION} == "ROS1Noetic" ] || [ ${ROSVERSION} == "NoROSUbuntu2004" ]; then
#echo Installing DCV for Ubuntu 20.04
#wget https://d1uj6qtbmh3dt5.cloudfront.net/2022.2/Servers/nice-dcv-2022.2-14521-ubuntu2004-x86_64.tgz
#tar xvfz nice-dcv-2022.2-14521-ubuntu2004-x86_64.tgz
#cd nice-dcv-2022.2-14521-ubuntu2004-x86_64
#DEBIAN_FRONTEND=noninteractive apt-get install -y \
#./nice-dcv-server_2022.2.14521-1_amd64.ubuntu2004.deb \
#./nice-xdcv_2022.2.14521-1_amd64.ubuntu2004.deb
#else
#echo Installing DCV for Ubuntu 22.04
#wget https://d1uj6qtbmh3dt5.cloudfront.net/2022.2/Servers/nice-dcv-2022.2-14521-ubuntu2204-x86_64.tgz
#tar xvfz nice-dcv-2022.2-14521-ubuntu2204-x86_64.tgz
#cd nice-dcv-2022.2-14521-ubuntu2204-x86_64
#DEBIAN_FRONTEND=noninteractive apt-get install -y \
#./nice-dcv-server_2022.2.14521-1_amd64.ubuntu2204.deb \
#./nice-xdcv_2022.2.519-1_amd64.ubuntu2204.deb
#fi

cd /home/ubuntu

# create_dcv_conf
cat << 'EOF' > ./dcv.conf
[license]
[log]
[display]
[connectivity]
web-port=8080
web-use-https=false
[security]
authentication="none"
EOF

# mv_dcv_conf
mv ./dcv.conf /etc/dcv/dcv.conf

# enable usb
/usr/bin/dcvusbdriverinstaller --quiet

# Configure DCV Session
sudo su -l ubuntu -c dbus-launch gsettings set org.gnome.shell enabled-extensions "['ubuntu-dock@ubuntu.com']"
/sbin/iptables -A INPUT -p tcp ! -s localhost --dport 8080 -j DROP
systemctl enable dcvserver
systemctl start dcvserver

# Create service to launch DCV Session on server restart
cat << 'EOF' > /etc/systemd/system/dcvsession.service
[Unit]
Description=NICE DCV Session
After=dcvserver.service

[Service]
User=ubuntu
ExecStart=/usr/bin/dcv create-session cloud9-session --owner ubuntu

[Install]
WantedBy=multi-user.target
EOF

# text console: DCV virtual sessions only
systemctl isolate multi-user.target
systemctl set-default multi-user.target

sudo systemctl daemon-reload
sudo systemctl enable dcvsession
sudo systemctl start dcvsession
