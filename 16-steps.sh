set -x
cd /home/rose/tmp-ovn && export OVN_RUNDIR=$(pwd) && export OVN_LOGDIR=$(pwd) && export OVN_DBDIR=$(pwd) && export PATH=$PATH:/home/rose/ovn/utilities/ && export PATH=$PATH:/home/rose/ovn/northd/ && export PATH=$PATH:/home/rose/ovn/controller/ && cd /home/rose/tmp-ovs && export OVS_RUNDIR=$(pwd) && export OVS_LOGDIR=$(pwd) && export OVS_DBDIR=$(pwd)
rm -f /home/rose/tmp-ovs/conf2.db

# Create a new network namespace (ovs-second).
sudo ip netns add ovs-second
# Connect ovs-main with a ovs-second with a veth pair.
sudo ip link add ovs-second0 type veth peer name ovs-main1
sudo ip link set dev ovs-second0 netns ovs-second
sudo ip link set dev ovs-main1 netns ovs-main
sudo ip -netns ovs-second link set dev ovs-second0 up
sudo ip -netns ovs-main link set dev ovs-main1 up
# Create a separate OVS bridge (br-ext) in the old OVS and add a new veth port in it.
ovs-vsctl --db=unix:/home/rose/tmp-ovs/conf.sock add-br br-ext
ovs-vsctl --db=unix:/home/rose/tmp-ovs/conf.sock add-port br-ext ovs-main1
# Start new local ovsdb-server with new conf.db.
ovsdb-tool create /home/rose/tmp-ovs/conf2.db /home/rose/ovs/vswitchd/vswitch.ovsschema
ovsdb-server --detach --no-chdir --pidfile=/home/rose/tmp-ovs/conf2.pid -vconsole:off --log-file=/home/rose/tmp-ovs/db-conf2.log -vsyslog:off --remote=punix:/home/rose/tmp-ovs/conf2.sock /home/rose/tmp-ovs/conf2.db --unixctl=/home/rose/tmp-ovs/conf2.ctl
# Start new ovs-vswitchd in ovs-second.
sudo -E ip netns exec ovs-second ovs-vswitchd --detach --no-chdir --pidfile=/home/rose/tmp-ovs/ovs-vswitchd2.pid -vconsole:off --log-file=/home/rose/tmp-ovs/ovs-vswitchd2.log -vsyslog:off --unixctl=/home/rose/tmp-ovs/ovs-vswitchd2.ctl unix:/home/rose/tmp-ovs/conf2.sock
# Create a br-ext bridge in a new OVS and add the other veth port there.
ovs-vsctl --db=unix:/home/rose/tmp-ovs/conf2.sock add-br br-ext
ovs-vsctl --db=unix:/home/rose/tmp-ovs/conf2.sock add-port br-ext ovs-second0
# Start a new ovn-controller connecting to a new local ovsdb-server and the OLD sb-db.
ovs-vsctl --db=unix:/home/rose/tmp-ovs/conf2.sock set open_vswitch . external-ids:ovn-remote="unix:/home/rose/tmp-ovn/sb-db.sock"
sudo -E /home/rose/ovn/controller/ovn-controller --detach --no-chdir -vsyslog:off --pidfile=/home/rose/tmp-ovn/ovn-controller2.pid --log-file=/home/rose/tmp-ovn/ovn-controller.log -vconsole:off unix:/home/rose/tmp-ovs/conf2.sock
# Set system-id in the new local OVS database to 'second'.
ovs-vsctl --db=unix:$OVS_RUNDIR/conf2.sock set open_vswitch . external-ids:system-id="second"
# Set br-ex interface up in both namespaces and assign ip addresses, e.g. 172.16.0.1 and 172.16.0.2.
sudo ip -netns ovs-second link set dev br-ext up
sudo ip -netns ovs-main link set dev br-ext up
sudo ip -netns ovs-second addr add dev br-ext 172.16.0.2/24
sudo ip -netns ovs-main addr add dev br-ext 172.16.0.1/24
# Set ovn-encap-ip in local OVS databases equal to these ip addresses accordingly.
ovs-vsctl --db=unix:$OVS_RUNDIR/conf.sock set open_vswitch . external-ids:ovn-encap-ip="172.16.0.1" external-ids:ovn-encap-type=geneve
ovs-vsctl --db=unix:$OVS_RUNDIR/conf2.sock set open_vswitch . external-ids:ovn-encap-ip="172.16.0.2" external-ids:ovn-encap-type=geneve
# Set external-ids:ovn-bridge-mapping=physnet:br-ex.
ovs-vsctl --db=unix:$OVS_RUNDIR/conf2.sock set open_vswitch . external-ids:ovn-bridge-mappings=physnet:br-ext
ovs-vsctl --db=unix:$OVS_RUNDIR/conf.sock set open_vswitch . external-ids:ovn-bridge-mappings=physnet:br-ext
# Remove carol0 from OVS in ovs-main, move it to ovs-second namespace, add to br-int of a new OVS in ovs-second, set iface-id=carol.
sudo ip netns exec ovs-main ovs-vsctl --db=unix:$OVS_RUNDIR/conf.sock del-port br-int carol0
sudo ip -netns ovs-main link set carol0 netns ovs-second
sudo ip -netns ovs-second link set dev carol0 up
sudo ip -netns carol link set dev carol1 up
sudo ip netns exec ovs-second ovs-vsctl --db=unix:/home/rose/tmp-ovs/conf2.sock add-port br-int carol0
sudo ip netns exec ovs-second ovs-vsctl --db=unix:$OVS_RUNDIR/conf2.sock set interface carol0 external-ids:iface-id=carol
# Add a new logical switch port 'ext-port' to sw0.
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lsp-add sw0 ext-port
# lsp-set-type ext-port localnet
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lsp-set-type ext-port localnet
# lsp-set-addresses ext-port unknown
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lsp-set-addresses ext-port unknown
# lsp-set-options ext-port network_name=physnet
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lsp-set-options ext-port network_name=physnet

