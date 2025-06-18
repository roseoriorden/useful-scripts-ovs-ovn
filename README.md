# stateless-lb.sh
sets up a stateless lb using OVN with bob and carol as backends, allowing for communication between alice -> (bob || carol)

# Full topology:
Run `sudo -E bash do-everything.sh`
![topology](topology.png)
To undo everything, run `sudo -E bash stop-everything.sh`

# Environment Variables
## OVN & OVS env variables needed for this script
- `$OVN_RUNDIR = /path/to/tmp-ovn`
- `$OVS_RUNDIR = /path/to/tmp-ovs`
## Script specific env variable(s)
- `$OVN_DIR = /path/to/ovn`
## Other OVN & OVS env variables (do NOT need to be set for this script)
- `$OVN_LOGDIR = /path/to/tmp-ovn`
- `$OVN_DBDIR = /path/to/tmp-ovn`
- `$OVS_LOGDIR = /path/to/tmp-ovs`
- `$OVS_DBDIR = /path/to/tmp-ovs`
