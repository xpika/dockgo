function getPort(){                                                                                                                                                                           
  export CHECK="do while";                                                                                                                                                                    
  while [[ ! -z $CHECK ]]; do
    PORT=$(( ( RANDOM % 60000 )  + 1025 ))                                                                                                                                                    
    CHECK=$(sudo netstat -ap | grep $PORT)                                                                                                                                                    
  done                                                                                                                                                                                        
  echo $PORT                                                                                                                                                                                  
}

function dockclean(){
    docker rm -v $(docker ps --filter status=exited -q 2>/dev/null) 2>/dev/null
    docker rmi $(docker images --filter dangling=true -q 2>/dev/null) 2>/dev/null
}

deployRestarterCoreOS(){

cat << EOF > /etc/systemd/system/date.service

[Unit]                                                                                                                                                                                        
Description=Prints date into /tmp/date file                                                                                                                                                   
                                                                                                                                                                                              
[Service]                                                                                                                                                                                     
Type=oneshot                                                                                                                                                                                  
ExecStart=/usr/bin/sh -c 'sh /root/script.sh;/usr/bin/date >> /tmp/date' 

EOF

cat << EOF > /etc/systemd/system/date.timer

[Unit]                                                                                                                                                                                        
Description=Run date.service every 10 minutes                                                                                                                                                 
                                                                                                                                                                                              
[Timer]                                                                                                                                                                                       
OnCalendar=*:0/01:00     

[Install]
WantedBy=multi-user.target

EOF

cat << EOF > /root/script.sh

docker start me2

EOF

sudo systemctl enable date.timer


}

alias dockls='docker ls --no-trunc'
alias dockephem='dockstart && dockenter && dockrm'
alias dockbuild='docker build -t "${PWD##*/}" .'
alias dockfreshbuild='docker build -t --no-cache "${PWD##*/}" .'
alias dockrm='docker rm -f "${PWD##*/}"'
alias dockrun='docker run $( [ -e host ] && echo -n '--net="host"' || echo -n '--net="the_net"') -h "${PWD##*/}" --user 0 $([ -d $HOME/code ] && echo -v $HOME/code:/root/code)  $( [ -e entrypoint ] && (echo -n "--entrypoint " ; cat entrypoint )  || echo "" ) --restart=always  $( [ -e ports ] && echo "$(cat ports | xargs -I% echo -n " -p % ")"  )  $( [ -e envs ] && echo "$(cat envs | xargs -I% echo -n " -e % ")"  )  -p $( [ -e fromport ] && cat fromport || getPort ):$( [ -e toport ] && cat toport || echo 80 ) -i -d -t -e "DISPLAY=unix:0.0" -v="/tmp/.X11-unix:/tmp/.X11-unix:rw"  -e PGID=`id -g` -e PUID=`id -u`  --privileged=true --name "${PWD##*/}"  "$( [ -e dockimage ] && cat dockimage || echo ${PWD##*/} )" '
alias dockattach='docker attach "${PWD##*/}"'
alias dockstop='docker stop "${PWD##*/}"'         
alias dockstart='docker start "${PWD##*/}"'
alias dockgo='dockbuild ; dockrun ; dockenter'
alias dockgoh='dockrm && dockgo'
alias docktry='docker run $([ -d /root/workdir ] && echo -v /root/workdir:/root/workdir) $( [ -e entrypoint ] && (echo -n "--entrypoint " ; cat entrypoint )  || echo "" )  -p $( [ -e fromport ] && cat fromport || getPort ):$( [ -e toport ] && cat toport || echo 80 ) -i -t -e "DISPLAY=unix:0.0" -v="/tmp/.X11-unix:/tmp/.X11-unix:rw"  -e PGID=`id -g` -e PUID=`id -u`  --privileged=true   "${PWD##*/}"'
alias dockstart_r='ssh $TARGET_MACHINE "docker start \"${PWD##*/}\""'
alias dockmo='dockrm ; dockgo'
alias dockenter='docker exec -i -t "${PWD##*/}" script --force -c " export LANG=C.UTF-8 LC_ALL=en_US.UTF-8 LANGUAGE=en_US.UTF-8 ;cd /root/workdir/ ; bash" /dev/null'
alias dockwork='docker exec -i -t "${PWD##*/}" script --force -c "  cd /root/workdir ; /bin/bash  " '
alias dockexec='docker exec -i -t "${PWD##*/}" '
alias dockmux='docker exec -i -t "${PWD##*/}" script --force -c bash -c "tmux attach"'
alias dockcommit='docker commit "${PWD##*/}" "${PWD##*/}"'
alias dockhiber='dockstop;dockcommit && dockrm'
alias dockip='docker inspect --format "{{ .NetworkSettings.Networks.bridge.IPAddress }}"  "${PWD##*/}"'
alias dockid='docker inspect --format {{.Id}} "${PWD##*/}" '
alias dockmid='cat /var/lib/docker/image/aufs/layerdb/mounts/`dockid`/mount-id'
alias dockdir='echo /var/lib/docker/aufs/diff/`dockmid`'
alias dockln='ln -s `dockdir` mount'
alias dockstorage='sudo docker info|grep "Storage Driver"'
alias dockutfinst='docker exec -i -t "${PWD##*/}" sh -c "(locale-gen en_US.UTF-8);(echo export LANG=C.UTF-8 LC_ALL=en_US.UTF-8 LANGUAGE=en_US.UTF-8 >> ~/.bashrc ) "'
alias dockvimmousedis='docker exec -i -t "${PWD##*/}" sh -c "echo set mouse= >> ~/.vimrc  "'
alias dockcabalpathadd='docker exec -i -t "${PWD##*/}" sh -c "echo PATH=~/.cabal/bin:$PATH >> /root/.bashrc  "'
function docksshinst(){
  docker exec -i -t "${PWD##*/}" sh -c 'apt-get install -y ssh ; sed -i "s/^PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config ; service ssh start'
}
alias dockdrestart="systemctl restart docker"
alias dockstoprestart="docker update --restart=no ${PWD##*/}"
alias dockstap='dockstoprestart ; dockstop'
alias dockcleani='docker images -q | xargs docker rmi'
function dockcp () { 

 docker cp ${PWD##*/}:$1 .

}

# omitting -f will prevent removing things in use"
alias dockprune='docker rm $(docker ps -q) ; docker rmi $(docker images -q)'

# dont use this i found it to be buggy
function dockmount(){
  DOCKER_AUFS_PATH="/var/lib/docker/aufs"
  DOCKER_AUFS_LAYERS="${DOCKER_AUFS_PATH}/layers/"
  DOCKER_AUFS_DIFF="${DOCKER_AUFS_PATH}/diff"
  
  BRANCH="br"
  IMAGE=`dockmid`
  TARGET="mymount"
  while read LAYER; do
          BRANCH+=":${DOCKER_AUFS_DIFF}/${LAYER}=rw"
  done < "${DOCKER_AUFS_LAYERS}/${IMAGE}"
  umount "${TARGET}"
  mount -t aufs -o "${BRANCH}" none "${TARGET}"
}
