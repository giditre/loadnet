# Laboratory of Advanced Networking

All commands specified below are to be executed in the main directory of the repository (e.g., if the repo was cloned in the home directory of the user, then the home directory of the repo will be ~/loadnet).

**Note**: the instructions for each lab activity (LA) are written considering each LA to be independent of the others; however, the instructions for each part may rely on those for the previous part(s) of the same LA (e.g., the instructions for LA2b needs to be performed after those for LA2a).

## LA1 - topology

### LA1a - virtualized equipment configuration

```bash
la1_topology/la1a_virtual.sh -G 4 all
```

### LA1b - physical equipment configuration

```bash
tools/replace.py -G 4 la1_topology/ansible/inventory.yml
ansible-playbook -kK -i la1_topology/ansible/G4_inventory.yml la1_topology/ansible/cisco_ios_command.yml
```

## LA2 - OSPF

### LA2a - single-area OSPF

```bash
tools/replace.py -G 4 la2_ospf/la2a_R* la2_ospf/ansible/inventory.yml
la2_ospf/la2a_single.sh -G 4 all
ansible-playbook -kK -i la2_ospf/ansible/G4_inventory.yml la2_ospf/ansible/cisco_ios_command.yml
```

### LA2b - multi-area OSPF

```bash
la2_ospf/la2b_multi.sh -G 4 all
```

## LA3 - BGP

### LA3a - basic BGP

```bash
tools/replace.py -y la3_bgp/la3a_R* la3_bgp/ansible/inventory.yml
la3_ospf/la3a_basic.sh -G 4 all
ansible-playbook -kK -i la3_bgp/ansible/G4_inventory.yml la3_bgp/ansible/cisco_ios_command.yml
```

### LA3b - BGP routing policies

Coming soon...

<!-- ```bash
la3_ospf/la3b_policies.sh -G 4 all
``` -->

## LA4 - MPLS

### LA4a - basic MPLS

Coming soon...

### LA4b - MPLS traffic engineering

Coming soon...

## LA5 - SDN

Coming soon...