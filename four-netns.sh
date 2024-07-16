#!/bin/bash
set -x
ip netns del ovs-main
ip netns add ovs-main
i=0
for ns in alice bob carol; do
	let i=$((i+1))
	ip netns del $ns
	ip link del ${ns}0
	ip netns add $ns
	ip link add ${ns}0 type veth peer name ${ns}1
	ip link set dev ${ns}0 netns ovs-main
	ip link set dev ${ns}1 netns $ns
	ip -netns ovs-main link set dev ${ns}0 up
	ip -netns $ns link set dev ${ns}1 up
	ip -netns $ns addr add dev ${ns}1 10.0.0.${i}/24
	ip -netns $ns link set dev ${ns}1 addr aa:55:aa:55:00:0${i}
done
