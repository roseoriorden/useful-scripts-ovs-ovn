set -x

pkill ovs-vswitchd
pkill ovsdb-server
pkill ovn-controller
pkill ovn-northd

rm -rf /home/rose/tmp-ovn/
rm -rf /home/rose/tmp-ovs/
