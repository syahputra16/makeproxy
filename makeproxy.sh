#!/bin/bash

apt-get update
apt-get upgrade -y
apt-get autoremove -y
apt-get autoclean -y
apt-get clean -y
apt-get install fail2ban software-properties-common -y
apt-get install build-essential libevent-dev libssl-dev -y

isp=$(curl -s https://www.whoismyisp.org | grep -oP '\bisp">\K[^<]+')
echo "Would you like to use IP auth or password? (IP/password)"
read auth
if [[ $auth == *"pass"* ]] || [[ $auth == *"Pass"* ]]
then
echo "Enter proxy username: "
read username
echo "Enter proxy password: "
read password
else
echo "Enter authorization IP: "
read authip
fi

cd /usr/local/etc
wget https://github.com/mainlyek/3proxy/archive/refs/tags/Anonymous.tar.gz
tar zxvf 0.8.12.tar.gz
rm 0.8.12.tar.gz
mv 3proxy-0.8.12 3proxy 
cd 3proxy
make -f Makefile.Linux
make -f Makefile.Linux install
mkdir log
cd cfg
rm 3proxy.cfg.sample

echo "#!/usr/local/bin/3proxy
daemon
pidfile /usr/local/etc/3proxy/3proxy.pid
nserver 1.1.1.1
nserver 1.0.0.1
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
log /usr/local/etc/3proxy/log/3proxy.log D
logformat \"- +_L%t.%. %N.%p %E %U %C:%c %R:%r %O %I %h %T\"
archiver rar rar a -df -inul %A %F
rotate 30
internal 0.0.0.0
external 0.0.0.0
authcache ip 60




proxy -p3130 -a -n
proxy -p3131 -6 -a -n -i0.0.0.0 -e::0
" >> /usr/local/etc/3proxy/cfg/3proxy.cfg
chmod 700 3proxy.cfg
sed -i '14s/.*/       \/usr\/local\/etc\/3proxy\/cfg\/3proxy.cfg/' /usr/local/etc/3proxy/scripts/rc.d/proxy.sh
sed -i "4ish /usr/local/etc/3proxy/scripts/rc.d/proxy.sh start" /etc/rc.local

#Add selected authorization to configuration file
if [[ $auth == *"pass"* ]] || [[ $auth == *"Pass"* ]]
then
sed -i '17s/.*/auth strong/' /usr/local/etc/3proxy/cfg/3proxy.cfg
sed -i "15s/.*/users $username:CL:$password/" /usr/local/etc/3proxy/cfg/3proxy.cfg 
sed -i "18s/.*/allow $username /" /usr/local/etc/3proxy/cfg/3proxy.cfg 

else
sed -i '17s/.*/auth iponly/' /usr/local/etc/3proxy/cfg/3proxy.cfg
sed -i "18s/.*/allow * $authip/" /usr/local/etc/3proxy/cfg/3proxy.cfg 
fi
if [[ $ifextra == *"y"* ]] || [[ $ifextra == *"Y"* ]]
then
n=0
cat /etc/tmp | while read line
do
n=$((n+1)); echo "proxy -p313$n -a -n -i$line -e$line" >> /usr/local/etc/3proxy/cfg/3proxy.cfg
done
fi
sh /usr/local/etc/3proxy/scripts/rc.d/proxy.sh start
echo
/bin/echo -e "\e[1;36m#-------------------------------------------------------------#\e[0m"
/bin/echo -e "\e[1;36m#                Proxy Creation Successful!                   #\e[0m"
/bin/echo -e "\e[1;36m#-------------------------------------------------------------#\e[0m"
echo

echo "Your new proxies are:"
mainIP=$(curl -s http://ipinfo.io/ip)
echo "IPV4 proxy"
echo "$mainIP:3130:$username:$password"
echo "IPV6 proxy"
echo "$mainIP:3131:$username:$password"
