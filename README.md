# dockgo

concise way to spin up docker instances

 step 1. create directory                                                                                                                          
 step 2. create Dockerfile                                                                                                                                                                  
 step 3. enter "dockgo" and your in!        

### to try:

```
source <(curl https://raw.githubusercontent.com/xpika/dockgo/master/dockgo.sh) 
```

### to install
```
curl https://raw.githubusercontent.com/xpika/dockgo/master/dockgo.sh > ~/dockgo.sh 
```
or
```
wget https://raw.githubusercontent.com/xpika/dockgo/master/dockgo.sh -O ~/dockgo.sh
```
then
```
echo source ~/dockgo.sh >> ~/.bashrc
bash
```

then
```
docker network create the_net
```
