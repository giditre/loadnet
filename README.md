# Laboratory of Advanced Networking

All commands specified below are meant to be executed in the main directory of the repository (e.g., if the repo was cloned in the home directory of the user, then the home directory of the repo will be ~/loadnet). Adjust the value of parameter G to the appropriate value for your group (in the examples below, G is 4).

**Note**: the instructions for each lab activity (LA) are written considering each LA to be independent of the others; however, the instructions for each part may rely on those for the previous part(s) of the same LA (e.g., the instructions for LA2b needs to be performed after those for LA2a).

## Preliminary configuration

Run these commands for every user who wants tu use Ansible on the Ansible Management Node (i.e., the VM of the group)

```bash
pip3 install paramiko
ansible-galaxy collection install ansible.netcommon cisco.ios
```

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

```bash
tools/replace.py -G 4 la2_ospf/la2a_R* la2_ospf/la2b_R* la2_ospf/ansible/inventory.yml
```

### LA2a - single-area OSPF

```bash
la2_ospf/la2a_single.sh -G 4 all
ansible-playbook -kK -i la2_ospf/ansible/G4_inventory.yml la2_ospf/ansible/cisco.yml
```

### LA2b - multi-area OSPF

```bash
la2_ospf/la2b_multi.sh -G 4 all
```

## LA3 - BGP

```bash
tools/replace.py -G 4 la3_bgp/la3a_R* la3_bgp/la3b_R* la3_bgp/ansible/inventory.yml
```

### LA3a - basic BGP

```bash
la3_bgp/la3a_basic.sh -G 4 all
ansible-playbook -kK -i la3_bgp/ansible/G4_inventory.yml la3_bgp/ansible/cisco.yml
```

### LA3b - BGP routing policies

```bash
la3_bgp/la3b_policies.sh -G 4 all
```

## Other LAs

No additional material about the other LAs is available on this repo.
