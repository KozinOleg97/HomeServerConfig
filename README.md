## Deploy

### Install docker and docker-compose

### Install git, crone

```bash
sudo apt update && sudo apt install git cron -y
```

### Place repo in opt/docker

```bash
git clone https://github.com/KozinOleg97/HomeServerConfig /tmp/homeserver
cp -r /tmp/homeserver/. /opt/docker-restore
rm -rf /tmp/homeserver
```

### Fill in the .env file

```bash
cp .env.example .env
```

### Rut SSL script

```bash
cd /opt/docker
bash ssl/init-acme.sh
```

### Start docker-compose

```bash
docker-compose up -d
```