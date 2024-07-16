#!/bin/bash

# ovsdb-server --detach --no-chdir --pidfile -vconsole:off --log-file -vsyslog:off --remote=punix:$(pwd)/db.sock
sudo -E ip netns exec ovs-main ovs-vswitchd --detach --no-chdir --pidfile -vconsole:off --log-file -vsyslog:off
cd /home/rose/ovn
export OVN_RUNDIR=$(pwd)
export PATH=$PATH:/home/rose/ovn/utilities/
export PATH=$PATH:/home/rose/ovn/northd/
export PATH=$PATH:/home/rose/ovn/controller/
cd ../tmp-ovs
ovsdb-tool create nb.db /home/rose/ovn/ovn-nb.ovsschema
ovsdb-tool create sb.db /home/rose/ovn/ovn-sb.ovsschema
ovsdb-server --detach --no-chdir --pidfile=nb.pid -vconsole:off --log-file -vsyslog:off --remote=punix:$(pwd)/nb-db.sock nb.db
ovsdb-server --detach --no-chdir --pidfile=sb.pid -vconsole:off --log-file -vsyslog:off --remote=punix:$(pwd)/sb-db.sock sb.db
ovn-northd --detach --no-chdir --pidfile=ovn-northd.pid -vconsole:off --log-file=ovn-northd.log -vsyslog:off --ovnsb-db=unix:$(pwd)/sb-db.sock --ovnnb-db=unix:$(pwd)/nb-db.sock
ovn-appctl -t ovn-northd status
ovn-appctl -t ovn-northd sb-connection-status
sudo -E PATH=$PATH /home/rose/ovn/controller/ovn-controller --detach --no-chdir -vsyslog:off --log-file=$(pwd)/ovn-controller.log --pidfile=$(pwd)/ovn-controller.pid -vconsole:off unix:$(pwd)/db.sock
ovs-vsctl del-br br0
ovs-vsctl add-port br-int alice0
ovs-vsctl add-port br-int bob0
ovs-vsctl add-port br-int carol0
ovs-vsctl set open_vswitch . external-ids:system-id="ovn-main"
ovs-vsctl set open_vswitch . external-ids:ovn-remote="unix:/home/rose/tmp-ovs/sb-db.sock"
ovs-vsctl set open_vswitch . external-ids:ovn-encap-ip="127.0.0.1" external-ids:ovn-encap-type=geneve
ovn-nbctl --db=unix:/home/rose/tmp-ovs/nb-db.sock ls-add sw0
ovn-nbctl --db=unix:/home/rose/tmp-ovs/nb-db.sock lsp-add sw0 alice
ovn-nbctl --db=unix:/home/rose/tmp-ovs/nb-db.sock lsp-add sw0 bob
ovn-nbctl --db=unix:/home/rose/tmp-ovs/nb-db.sock lsp-add sw0 carol
ovs-vsctl set interface alice0 external-ids:iface-id=alice
ovs-vsctl set interface alice0 external-ids:iface-id=bob
ovs-vsctl set interface alice0 external-ids:iface-id=carol
ovn-nbctl --db=unix:/home/rose/tmp-ovs/nb-db.sock lb-add lb 10.0.0.17 10.0.0.3,10.0.0.2
# time to connect the lb and switch to a lr
ovn-nbctl --db=unix:/home/rose/tmp-ovs/nb-db.sock lr-add lr0
ovn-nbctl --db=unix:/home/rose/tmp-ovs/nb-db.sock lrp-add lr0 lr0-sw0 00:00:00:00:ff:01 10.0.0.18/24
ovn-nbctl --db=unix:/home/rose/tmp-ovs/nb-db.sock lsp-add sw0 sw0-lr0
ovn-nbctl --db=unix:/home/rose/tmp-ovs/nb-db.sock lsp-set-type sw0-lr0 router
ovn-nbctl --db=unix:/home/rose/tmp-ovs/nb-db.sock lsp-set-type-addresses sw0-lr0 router
ovn-nbctl --db=unix:/home/rose/tmp-ovs/nb-db.sock lsp-set-addresses sw0-lr0 router
ovn-nbctl --db=unix:/home/rose/tmp-ovs/nb-db.sock lsp-set-options sw0-lr0 router-port=lr0-sw0
ovn-nbctl --db=unix:/home/rose/tmp-ovs/nb-db.sock lr-lb-add lr0 lb


# ovn-trace --db=unix:$(pwd)/sb-db.sock sw0 'inport == "alice" && ip4.dst == 10.0.0.2 && eth.dst == aa:55:aa:55:00:02'


#then you can run nc in two other terminals as bob and carol
#sudo ip netns exec carol nc -k -l 0.0.0.0 12346
