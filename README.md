# loadnet

## LA2 - OSPF

### LA2a - single-area OSPF

```bash
tools/replace.py -G 4 la2_ospf/la2a_R*
la2_ospf/la2a_single.sh -G 4 all
ansible-playbook -i la2_ospf/ansible/G4_inventory.yml la2_ospf/ansible/cisco_ios_command.yml
```

### LA2b - multi-area OSPF

```bash
tools/replace.py -G 4 la2_ospf/la2b_R*
la2_ospf/la2b_multi.sh -G 4 all
ansible-playbook -i la2_ospf/ansible/G4_inventory.yml la2_ospf/ansible/cisco_ios_command.yml
```

## LA3 - BGP

### LA3a - basic BGP

```bash
tools/replace.py -y la3_bgp/la3a_R*
la3_ospf/la2b_multi.sh -G 4 all
ansible-playbook -i la3_bgp/ansible/G4_inventory.yml la3_bgp/ansible/cisco_ios_command.yml
```

### LA3b - BGP routing policies

Coming soon...

## LA4 - MPLS

### LA4a - basic MPLS

Coming soon...

### LA4b - MPLS traffic engineering

Coming soon...

## LA5 - SDN

Coming soon...