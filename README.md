# stateless-lb.sh
sets up a stateless lb using OVN with bob and carol as backends, allowing for communication between alice -> (bob || carol)

# Full topology:
run `bash ./do-everything.sh`
![topology](topology.png)

# Environment Variables
## OVN & OVS env variables
- `$OVN_RUNDIR = /path/to/tmp-ovn`
- `$OVN_LOGDIR = /path/to/tmp-ovn`
- `$OVN_DBDIR = /path/to/tmp-ovn`
- `$OVS_RUNDIR = /path/to/tmp-ovs`
- `$OVS_LOGDIR = /path/to/tmp-ovs`
- `$OVS_DBDIR = /path/to/tmp-ovs`
## Script specific env variable(s)
- `$OVN_DIR = /path/to/ovn`
