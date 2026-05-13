## 👋 Welcome to squidguard 🚀  

squidguard README  
  
  
## Install my system scripts  

```shell
 sudo bash -c "$(curl -q -LSsf "https://github.com/systemmgr/installer/raw/main/install.sh")"
 sudo systemmgr --config && sudo systemmgr install scripts  
```
  
## Automatic install/update  
  
```shell
dockermgr update squidguard
```
  
## Install and run container
  
```shell
dockerHome="/var/lib/srv/$USER/docker/casjaysdevdocker/squidguard/squidguard/latest/rootfs"
mkdir -p "/var/lib/srv/$USER/docker/squidguard/rootfs"
git clone "https://github.com/dockermgr/squidguard" "$HOME/.local/share/CasjaysDev/dockermgr/squidguard"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/squidguard/rootfs/." "$dockerHome/"
docker run -d \
--restart always \
--privileged \
--name casjaysdevdocker-squidguard-latest \
--hostname squidguard \
-e TZ=${TIMEZONE:-America/New_York} \
-v "$dockerHome/data:/data:z" \
-v "$dockerHome/config:/config:z" \
-p 80:80 \
casjaysdevdocker/squidguard:latest
```
  
## via docker-compose  
  
```yaml
version: "2"
services:
  ProjectName:
    image: casjaysdevdocker/squidguard
    container_name: casjaysdevdocker-squidguard
    environment:
      - TZ=America/New_York
      - HOSTNAME=squidguard
    volumes:
      - "/var/lib/srv/$USER/docker/casjaysdevdocker/squidguard/squidguard/latest/rootfs/data:/data:z"
      - "/var/lib/srv/$USER/docker/casjaysdevdocker/squidguard/squidguard/latest/rootfs/config:/config:z"
    ports:
      - 80:80
    restart: always
```
  
## Get source files  
  
```shell
dockermgr download src casjaysdevdocker/squidguard
```
  
OR
  
```shell
git clone "https://github.com/casjaysdevdocker/squidguard" "$HOME/Projects/github/casjaysdevdocker/squidguard"
```
  
## Build container  
  
```shell
cd "$HOME/Projects/github/casjaysdevdocker/squidguard"
buildx 
```
  
## Authors  
  
🤖 casjay: [Github](https://github.com/casjay) 🤖  
⛵ casjaysdevdocker: [Github](https://github.com/casjaysdevdocker) [Docker](https://hub.docker.com/u/casjaysdevdocker) ⛵  
