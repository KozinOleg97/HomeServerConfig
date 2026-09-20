cd /opt/docker/dns/unbound/data

# Скачать список корневых серверов
wget -O root.hints https://www.internic.net/domain/named.root

# Сгенерировать ключ DNSSEC
sudo apt update && sudo apt install unbound-anchor -y   # для Debian/Ubuntu
# или: sudo yum install unbound
unbound-anchor -a root.key