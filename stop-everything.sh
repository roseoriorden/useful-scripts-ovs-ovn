set -x

pkill ovs-vswitchd
pkill ovsdb-server
pkill ovn-controller
pkill ovn-northd

rm -rf $OVN_RUNDIR/*
rm -rf $OVS_RUNDIR/*
