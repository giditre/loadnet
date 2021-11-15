#!/bin/bash

# user functions
usage(){
  echo "Usage: $0 [-G GROUP] [-I VM_INTERFACE] <add|del|all|test>"
}
docker_ping(){
  sudo docker exec $1 ping -c1 -w1 -W1 $2 | grep -e "bytes from" -e "received"
}
docker_arping(){
  sudo docker exec -it $1 arping -f $2
}

# default argument values
G=5
IFACE=enp6s0
ASK=true

while getopts ":hG:I:y" OPT ; do
  case $OPT in
    h) # display help
      usage
      exit 1
      ;;
    G) # group number
      if [[ $OPTARG -ge 1 && $OPTARG -le 4 ]] ; then
        G=$OPTARG
      else
        echo "ERROR: value of G must be in range [1,4]"
        exit 1
      fi
      ;;
    I) # VM interface name
      if ip -o link | grep -q $OPTARG ; then
        IFACE=$OPTARG
      else
        echo "ERROR: interface $OPTARG not found"
        exit 1
      fi
      ;;
    y) # do not ask for confirmation on parameters
      ASK=false
      ;;
    \?) # invalid option
      echo "ERROR: invalid option $OPTARG"
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

# check number of positional arguments
if [[ $# -ne 1 ]]; then
  echo "ERROR: invalid number of positional arguments"
  usage
  exit 1
fi

# check validity of first argument
if ! [[ "$1" =~ ^(add|del|all|test)$ ]]; then
  echo "ERROR: invalid argument $1"
  usage
  exit 1
fi
ACTION=$1

X=$((10*G))

echo "The script is about to run with parameters
G=$G
X=$X
IFACE=$IFACE
ACTION=$ACTION
"

if $ASK ; then
  # ask user if sure
  read -p "Are you sure? [y/n] " -r R
  if [[ ! $R =~ ^[Yy]$ ]] ; then
    echo "No changes made."
    exit 1
  fi
fi

# invoke something with sudo just to make the system request the password
sudo ip link > /dev/null 2>&1

if [[ $ACTION =~ ^(all|del)$ ]] ; then

  echo "Remove virtual network topology"

  # sudo docker container stop h1 h2 R1 R2 R3
  # sudo docker container rm h1 h2 R1 R2 R3
  echo "Remove all Docker containers named R* or h*"
  NAMES=$(sudo docker container ls -f name=^[hR][0-9]+$ --format "{{.Names}}" | sort)
  if [[ -n $NAMES ]] ; then
    sudo docker container stop $NAMES
    sudo docker container rm $NAMES
  else
    echo "...no such containers was found"
  fi

  # net$((X+1)) net$((X+2)) net$((X+3)) net$((X+4)) vlan$((X+1)) vlan$((X+2))
  echo "Remove all Docker networks named net* or vlan*"
  NAMES=$(sudo docker network ls -f name=^net[0-9]+$ -f name=^vlan[0-9]+$ --format "{{.Name}}" | sort)
  if [[ -n $NAMES ]] ; then
    sudo docker network rm $NAMES
  else
    echo "...no such networks was found"
  fi
  
  echo "Remove VLAN sub-interface from VM interface"
  for VID in $((X+1)) $((X+2)) ; do
    if ip -o link | grep -q $IFACE.$VID ; then
      sudo ip link set $IFACE.$VID nomaster
      sudo ip link set $IFACE.$VID down
      sudo ip link del $IFACE.$VID
    else
      echo "...no interface called $IFACE.$VID was found"
    fi
  done

fi

if [[ $ACTION =~ ^(all|add)$ ]] ; then

  echo "Create virtual network topology"

  # check if networks and/or containers to be created already exist
  NAMES=$(sudo docker network ls -f name=^net[0-9]+$ -f name=^vlan[0-9]+$ --format "{{.Name}}" | sort)
  if [[ -n $NAMES ]] ; then
    echo "...but here are existing networks with intended names. Please check then run again."
    exit 1
  fi
  NAMES=$(sudo docker container ls -f name=^[hR][0-9]$ --format "{{.Names}}" | sort)
  if [[ -n $NAMES ]] ; then
    echo "...but here are existing containers with intended names. Please check then run again."
    exit 1
  fi
  if ip -o link | grep -q -E "$IFACE\.[0-9]+" ; then
    echo "...but here are existing sub-interfaces with intended names. Please check then run again."
    exit 1
  fi

  echo "Create end-host networks"
  sudo docker network create --subnet 192.168.$((X+101)).0/24 -o com.docker.network.bridge.name=br-net$((X+1)) net$((X+1))
  sudo docker network create --subnet 192.168.$((X+102)).0/24 -o com.docker.network.bridge.name=br-net$((X+2)) net$((X+2))

  echo "Create end-hosts"
  sudo docker run -dit --name h1 --hostname h1 --network net$((X+1)) --ip 192.168.$((X+101)).10 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN alpine
  sudo docker run -dit --name h2 --hostname h2 --network net$((X+2)) --ip 192.168.$((X+102)).20 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN alpine
 
  echo "Create routers R1 and R2"
  sudo docker run -dit --name R1 --hostname R1 --network net$((X+1)) --ip 192.168.$((X+101)).254 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN giditre/frr
  sudo docker run -dit --name R2 --hostname R2 --network net$((X+2)) --ip 192.168.$((X+102)).254 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN giditre/frr

  echo "Set R1 and R2 as default gw for h1 and h2"
  sudo docker exec -it h1 ip route change default via 192.168.$((X+101)).254
  sudo docker exec -it h2 ip route change default via 192.168.$((X+102)).254

  echo "Create intermediate networks"
  sudo docker network create --subnet 192.168.$((X+3)).0/25 -o com.docker.network.bridge.name=br-net$((X+3)) net$((X+3))
  sudo docker network create --subnet 192.168.$((X+4)).0/25 -o com.docker.network.bridge.name=br-net$((X+4)) net$((X+4))

  echo "Connect R1 and R2 to intermediate networks"
  sudo docker network connect --ip 192.168.$((X+3)).10 net$((X+3)) R1
  sudo docker network connect --ip 192.168.$((X+4)).20 net$((X+4)) R2
 
  echo "Create routers R7 and R8"
  sudo docker run -dit --name R7 --hostname R7 --network net$((X+3)) --ip 192.168.$((X+3)).70 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN giditre/frr
  sudo docker run -dit --name R8 --hostname R8 --network net$((X+4)) --ip 192.168.$((X+4)).80 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN giditre/frr

  echo "Create peripheral networks"
  sudo docker network create --subnet 192.168.$((X+3)).128/26 -o com.docker.network.bridge.name=br-net$((X+5)) net$((X+5))
  sudo docker network create --subnet 192.168.$((X+3)).192/26 -o com.docker.network.bridge.name=br-net$((X+6)) net$((X+6))
  sudo docker network create --subnet 192.168.$((X+4)).128/26 -o com.docker.network.bridge.name=br-net$((X+7)) net$((X+7))
  sudo docker network create --subnet 192.168.$((X+4)).192/26 -o com.docker.network.bridge.name=br-net$((X+8)) net$((X+8))

  echo "Connect R7 and R8 to peripheral networks"
  sudo docker network connect --ip 192.168.$((X+3)).170 net$((X+5)) R7
  sudo docker network connect --ip 192.168.$((X+3)).207 net$((X+6)) R7
  sudo docker network connect --ip 192.168.$((X+4)).180 net$((X+7)) R8
  sudo docker network connect --ip 192.168.$((X+4)).208 net$((X+8)) R8

  echo "Create end-hosts on peripheral networks"
  sudo docker run -dit --name h5 --hostname h5 --network net$((X+5)) --ip 192.168.$((X+3)).150 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN alpine
  sudo docker run -dit --name h6 --hostname h6 --network net$((X+6)) --ip 192.168.$((X+3)).196 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN alpine
  sudo docker run -dit --name h7 --hostname h7 --network net$((X+7)) --ip 192.168.$((X+4)).170 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN alpine
  sudo docker run -dit --name h8 --hostname h8 --network net$((X+8)) --ip 192.168.$((X+4)).198 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN alpine

  echo "Set relevant router as default gw for end-hosts on peripheral networks"
  sudo docker exec h5 ip route change default via 192.168.$((X+3)).170
  sudo docker exec h6 ip route change default via 192.168.$((X+3)).207
  sudo docker exec h7 ip route change default via 192.168.$((X+4)).180
  sudo docker exec h8 ip route change default via 192.168.$((X+4)).208

  echo "Create interconnection network"
  sudo docker network create --subnet 10.0.$((X+100)).0/24 -o com.docker.network.bridge.name=br-net$((X+100)) net$((X+100))

  echo "Connect R7 to interconnection network"
  sudo docker network connect --ip 10.0.$((X+100)).70 net$((X+100)) R7

  echo "Create router R9"
  sudo docker run -dit --name R9 --hostname R9 --network net$((X+100)) --ip 10.0.$((X+100)).90 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN giditre/frr

  echo "Create last peripheral network"
  sudo docker network create --subnet 192.168.$((X+9)).0/24 -o com.docker.network.bridge.name=br-net$((X+9)) net$((X+9))
  
  echo "Connect R9 to last peripheral network"
  sudo docker network connect --ip 192.168.$((X+9)).90 net$((X+9)) R9

  echo "Create end-host on last peripheral network"
  sudo docker run -dit --name h9 --hostname h9 --network net$((X+9)) --ip 192.168.$((X+9)).9 --cap-add=NET_ADMIN --cap-add=SYS_ADMIN alpine

  echo "Set R9 as default gw for h9"
  sudo docker exec h9 ip route change default via 192.168.$((X+9)).90
 
  echo "Create vlan networks"
  sudo docker network create --subnet 172.16.$((X+1)).0/24 -o com.docker.network.bridge.name=br-vlan$((X+1)) vlan$((X+1))
  sudo docker network create --subnet 172.16.$((X+2)).0/24 -o com.docker.network.bridge.name=br-vlan$((X+2)) vlan$((X+2))

  echo "Connect R1 and R2 to vlan networks"
  sudo docker network connect --ip 172.16.$((X+1)).10 vlan$((X+1)) R1
  sudo docker network connect --ip 172.16.$((X+2)).20 vlan$((X+2)) R2

  echo "Configure vlan sub-interfaces on VM interface"
  echo "...make sure interface $IFACE is up"
  sudo ip link set $IFACE up
  for VID in $((X+1)) $((X+2)) ; do
    echo "...create interface $IFACE.$VID"
    sudo ip link add link $IFACE name $IFACE.$VID type vlan id $VID
    sudo ip link set $IFACE.$VID up
    sudo ip link set $IFACE.$VID master br-vlan$VID
  done

  # Quagga configurations
  FILENAMEPREFIX="G${G}_la2b_R${i}.conf"
  for i in 1 2 7 8 9 ; do
    echo "Configure Quagga on router R${i}"
    # set IP address to loopback interface
    sudo docker exec R${i} ip addr add $G.$G.$G.${i}/32 dev lo
    # check if conf file exists
    FILENAME="${FILENAMEPREFIX}_R${i}.conf"
    if [[ ! -f $FILENAME ]] ; then
      echo "WARNING: file $FILENAME not found"
      continue
    fi
    # copy conf file to router and initialize frr
    sudo docker cp $FILENAME R${i}:/etc/frr/frr.conf
    sudo docker exec R${i} sh -x /etc/frr/init.sh > /dev/null 2>&1
  done

fi

if [[ $ACTION =~ ^(all|test)$ ]] ; then

  echo "Ping from h1 to R1"
  docker_ping h1 192.168.$((X+101)).254

  echo "Ping from h2 to R2"
  docker_ping h2 192.168.$((X+102)).254

  echo "Ping from R1 to R7"
  docker_ping R1 192.168.$((X+3)).70

  echo "Ping from R2 to R8"
  docker_ping R2 192.168.$((X+4)).80

  echo "Ping from R1 to CiscoA"
  # docker_arping R1 172.16.$((X+101)).110
  docker_ping R1 172.16.$((X+1)).110
  
  echo "Ping from R2 to CiscoC"
  # docker_arping R2 172.16.$((X+102)).130
  docker_ping R2 172.16.$((X+2)).120

  echo "Ping from h1 to h2"
  docker_ping h1 192.168.$((X+102)).20

  echo "Ping from h5 to h8"
  docker_ping h5 192.168.$((X+4)).198

  echo "Ping from h7 to h9"
  docker_ping h7 192.168.$((X+9)).9

fi

echo "Done."
