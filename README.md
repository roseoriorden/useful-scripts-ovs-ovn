# stateless-lb.sh
sets up a stateless lb using OVN with bob and carol as backends, allowing for communication between alice -> (bob || carol)

# Full topology:
Run `sudo -E bash do-everything.sh`

Then, run:

in terminal 1:
`sudo ip netns exec carol nc -k -l 0.0.0.0 12346`

in terminal 2:
`sudo ip netns exec bob nc -k -l 0.0.0.0 12346`

in terminal 3:
`sudo ip netns exec alice nc 10.0.0.17 12346 <<< "write whatever you want here, and it will show up on bob or carol's end!"`

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
