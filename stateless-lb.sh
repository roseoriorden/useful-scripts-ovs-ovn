#!/bin/bash

set -x #prints
set -e #exits on error
#cd /home/rose/ovn && export OVN_RUNDIR=$(pwd) && export OVN_LOGDIR=$(pwd) && export OVN_DBDIR=$(pwd) && export PATH=$PATH:/home/rose/ovn/utilities/ && export PATH=$PATH:/home/rose/ovn/northd/ && export PATH=$PATH:/home/rose/ovn/controller/ && cd /home/rose/tmp-ovs && export OVS_RUNDIR=$(pwd) && export OVS_LOGDIR=$(pwd) && export OVS_DBDIR=$(pwd)
mkdir /home/rose/tmp-ovn/
mkdir /home/rose/tmp-ovs/
cd /home/rose/tmp-ovs
export OVS_RUNDIR=$(pwd)
export OVS_LOGDIR=$(pwd)
export OVS_DBDIR=$(pwd)
cd /home/rose/tmp-ovn
export OVN_RUNDIR=$(pwd)
export OVN_LOGDIR=$(pwd)
export OVN_DBDIR=$(pwd)
export PATH=$PATH:/home/rose/ovn/utilities/
export PATH=$PATH:/home/rose/ovn/northd/
export PATH=$PATH:/home/rose/ovn/controller/
rm -f $OVN_RUNDIR/nb.db
rm -f $OVN_RUNDIR/sb.db
rm -f $OVS_RUNDIR/conf.db
ovsdb-tool create nb.db /home/rose/ovn/ovn-nb.ovsschema
ovsdb-tool create sb.db /home/rose/ovn/ovn-sb.ovsschema
cd $OVS_RUNDIR
ovsdb-tool create conf.db /home/rose/ovs/vswitchd/vswitch.ovsschema
cd $OVN_RUNDIR
ovsdb-server --detach --no-chdir --pidfile=nb.pid -vconsole:off --log-file=nb-db.log -vsyslog:off --remote=punix:$OVN_RUNDIR/nb-db.sock nb.db
ovsdb-server --detach --no-chdir --pidfile=sb.pid -vconsole:off --log-file=sb-db.log -vsyslog:off --remote=punix:$OVN_RUNDIR/sb-db.sock sb.db
cd $OVS_RUNDIR
ovsdb-server --detach --no-chdir --pidfile=conf.pid -vconsole:off --log-file=db-conf.log -vsyslog:off --remote=punix:$OVS_RUNDIR/conf.sock conf.db
sudo -E PATH=$PATH ip netns exec ovs-main ovs-vswitchd --detach --no-chdir --pidfile=ovs-vswitchd.pid -vconsole:off --log-file=ovs-vswitchd.log -vsyslog:off --unixctl=ovs-vswitchd.ctl unix:$OVS_RUNDIR/conf.sock
#sudo /usr/share/openvswitch/scripts/ovs-ctl start
#to exit vswitchd:
#sudo -E PATH=$PATH ovs-appctl --target=/home/rose/ovn/ovs-vswitchd.ctl exit
# might need to do: sudo -E /home/rose/ovn/northd/ovn-northd ...
cd $OVN_RUNDIR
ovn-northd --detach --no-chdir --pidfile=ovn-northd.pid -vconsole:off --log-file=ovn-northd.log -vsyslog:off --ovnsb-db=unix:$OVN_RUNDIR/sb-db.sock --ovnnb-db=unix:$OVN_RUNDIR/nb-db.sock
# ovn-appctl -t ovn-northd status
# ovn-appctl -t ovn-northd sb-connection-status
ovs-vsctl --db=unix:$OVS_RUNDIR/conf.sock --may-exist add-br br-int
sudo -E PATH=$PATH /home/rose/ovn/controller/ovn-controller --detach --no-chdir -vsyslog:off --log-file=$OVN_RUNDIR/ovn-controller.log --pidfile=$OVN_RUNDIR/ovn-controller.pid -vconsole:off unix:$OVS_RUNDIR/conf.sock
ovs-vsctl --db=unix:$OVS_RUNDIR/conf.sock add-port br-int alice0
ovs-vsctl --db=unix:$OVS_RUNDIR/conf.sock add-port br-int bob0
ovs-vsctl --db=unix:$OVS_RUNDIR/conf.sock add-port br-int carol0
ovs-vsctl --db=unix:$OVS_RUNDIR/conf.sock set open_vswitch . external-ids:system-id="ovn-main"
ovs-vsctl --db=unix:$OVS_RUNDIR/conf.sock set open_vswitch . external-ids:ovn-remote="unix:$OVN_RUNDIR/sb-db.sock"
ovs-vsctl --db=unix:$OVS_RUNDIR/conf.sock set open_vswitch . external-ids:ovn-encap-ip="127.0.0.1" external-ids:ovn-encap-type=geneve
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock ls-add sw0
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lsp-add sw0 alice
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lsp-add sw0 bob
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lsp-add sw0 carol
ovs-vsctl --db=unix:$OVS_RUNDIR/conf.sock set interface alice0 external-ids:iface-id=alice
ovs-vsctl --db=unix:$OVS_RUNDIR/conf.sock set interface bob0 external-ids:iface-id=bob
ovs-vsctl --db=unix:$OVS_RUNDIR/conf.sock set interface carol0 external-ids:iface-id=carol
# time to connect the lb and switch to a lr
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lb-add lb 10.0.0.17 10.0.0.3,10.0.0.2
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lr-add lr0
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lrp-add lr0 lr0-sw0 00:00:00:00:ff:01 10.0.0.18/24
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lsp-add sw0 sw0-lr0
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lsp-set-type sw0-lr0 router
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lsp-set-addresses sw0-lr0 router
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lsp-set-addresses alice "aa:55:aa:55:00:01 10.0.0.1"
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lsp-set-addresses bob "aa:55:aa:55:00:02 10.0.0.2"
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lsp-set-addresses carol "aa:55:aa:55:00:03 10.0.0.3"
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lsp-set-options sw0-lr0 router-port=lr0-sw0
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock lr-lb-add lr0 lb
ovn-nbctl --db=unix:$OVN_RUNDIR/nb-db.sock ls-lb-add sw0 lb

# ovn-trace --db=unix:$(pwd)/sb-db.sock sw0 'inport == "alice" && ip4.dst == 10.0.0.2 && eth.dst == aa:55:aa:55:00:02'

# then you can run nc in two other terminals as bob and carol
# sudo ip netns exec carol nc -k -l 0.0.0.0 12346
# sudo ip netns exec alice nc 10.0.0.17 12346 <<< "hello"
