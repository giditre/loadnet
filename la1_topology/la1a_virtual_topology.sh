#!/bin/bash

usage(){
  echo "Usage: $0 <add|del|all|test>"
}

# check if first argument is present
if [[ -z $1 ]]; then
  usage
  exit 10
fi

# check if additional arguments are provided
if [[ $# -ge 2 ]]; then
  shift
  # echo "ERROR: unexpected argument(s) $@"
  echo "ERROR: too many arguments"
  usage
  exit 11
fi

if ! [[ "$1" =~ ^(add|del|all|test)$ ]]; then
  echo "ERROR: invalid argument $1"
  usage
  exit 12
fi
action=$1

X=50
iface=enp6s0

if [[ $action == all ]] || [[ $action == del ]]; then

  sudo docker container stop h1 h2 R1 R2 R3
  sudo docker container rm h1 h2 R1 R2 R3
  sudo docker network rm net$((X+1)) net$((X+2)) net$((X+3)) net$((X+4)) vlan$((X+1)) vlan$((X+2))
   
  sudo ip link set $iface.$((X+1)) nomaster
  sudo ip link set $iface.$((X+1)) down
  sudo ip link del $iface.$((X+1))

  sudo ip link set $iface.$((X+2)) nomaster
  sudo ip link set $iface.$((X+2)) down
  sudo ip link del $iface.$((X+2))

  sudo ip link set $iface down

fi

if [[ $action == all ]] || [[ $action == add ]]; then

  # create end-host networks
  sudo docker network create --subnet 192.168.$((X+101)).0/24 -o com.sudo docker.network.bridge.name=br-net$((X+1)) net$((X+1))
  sudo docker network create --subnet 192.168.$((X+102)).0/24 -o com.sudo docker.network.bridge.name=br-net$((X+2)) net$((X+2))

  # create end-hosts  
  sudo docker run -dit --name h1 --hostname h1 --network net$((X+1)) --ip 192.168.$((X+101)).10 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN alpine
  sudo docker run -dit --name h2 --hostname h2 --network net$((X+2)) --ip 192.168.$((X+102)).20 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN alpine
 
  # create routers R1 and R2
  sudo docker run -dit --name R1 --hostname R1 --network net$((X+1)) --ip 192.168.$((X+101)).254 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN giditre/frr
  sudo docker run -dit --name R2 --hostname R2 --network net$((X+2)) --ip 192.168.$((X+102)).254 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN giditre/frr

  # set R1 as default gw for h1
  sudo docker exec -it h1 ip route change default via 192.168.$((X+101)).254
  # set R2 as default gw for h2
  sudo docker exec -it h2 ip route change default via 192.168.$((X+102)).254

  # create intermediate networks
  sudo docker network create --subnet 172.16.$((X+3)).0/24 -o com.sudo docker.network.bridge.name=br-net$((X+3)) net$((X+3))
  sudo docker network create --subnet 172.16.$((X+4)).0/24 -o com.sudo docker.network.bridge.name=br-net$((X+4)) net$((X+4))

  # connect R1 and R2 to intermediate networks
  sudo docker network connect --ip 172.16.$((X+3)).10 net$((X+3)) R1
  sudo docker network connect --ip 172.16.$((X+4)).20 net$((X+4)) R2
 
  # create intermediate router R3
  sudo docker run -dit --name R3 --hostname R3 --network net$((X+3)) --ip 172.16.$((X+3)).30 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN giditre/frr

  # connect R3 to right network
  sudo docker network connect --ip 172.16.$((X+4)).30 net$((X+4)) R3
 
  # create vlan networks
  sudo docker network create --subnet 172.16.$((X+1)).0/24 -o com.sudo docker.network.bridge.name=br-vlan$((X+1)) vlan$((X+1))
  sudo docker network create --subnet 172.16.$((X+2)).0/24 -o com.sudo docker.network.bridge.name=br-vlan$((X+2)) vlan$((X+2))

  # connect R1 and R2 to vlan networks
  sudo docker network connect --ip 172.16.$((X+1)).10 vlan$((X+1)) R1
  sudo docker network connect --ip 172.16.$((X+2)).20 vlan$((X+2)) R2

  # configure vlan sub-interfaces on host interface
  sudo ip link set $iface up
  
  sudo ip link add link $iface name $iface.$((X+1)) type vlan id $((X+1))
  sudo ip link set $iface.$((X+1)) up
  sudo ip link set $iface.$((X+1)) master br-vlan$((X+1))
  
  sudo ip link add link $iface name $iface.$((X+2)) type vlan id $((X+2))
  sudo ip link set $iface.$((X+2)) up
  sudo ip link set $iface.$((X+2)) master br-vlan$((X+2))

fi

if [[ $action == all ]] || [[ $action == test ]]; then

  # h1 to R1
  sudo docker exec -it h1 ping -c 1 192.168.$((X+101)).254

  # h2 to R2
  sudo docker exec -it h2 ping -c 1 192.168.$((X+102)).254

  # R1 to R3
  sudo docker exec -it R1 ping -c 1 172.16.$((X+3)).30

  # R2 to R3
  sudo docker exec -it R2 ping -c 1 172.16.$((X+4)).30

  # R1 to CiscoA
  #sudo docker exec -it R1 arping -f 172.16.$((X+101)).110
  sudo docker exec -it R1 ping -c 1 172.16.$((X+1)).110
  
  # R2 to CiscoC
  #sudo docker exec -it R2 arping -f 172.16.$((X+102)).130
  sudo docker exec -it R2 ping -c 1 172.16.$((X+2)).120

fi
