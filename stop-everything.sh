declare -a env_vars=(
    "OVN_RUNDIR"
    "OVS_RUNDIR"
    "OVN_DIR"
)

all_vars_set=true

for var_name in OVN_RUNDIR OVS_RUNDIR
do
    if [ -z "${!var_name}" ]; then
        echo "$var_name must be set to proceed."
        all_vars_set=false
    else
        echo "$var_name is set to ${!var_name}"
    fi
done

if ! [ "$all_vars_set" = true ]; then
    echo "Failure: One or more required environment variables are not set. Please set them and try again."
    exit 1
fi



read -p "About to delete contents of $OVN_RUNDIR. Continue (y/n)?" choice
case "$choice" in
  y|Y ) rm -rf $OVN_RUNDIR/*; echo "Deletion complete";;
  n|N ) echo "Aborted";;
  * ) echo "Invalid, aborting";;
esac

read -p "About to delete contents of $OVS_RUNDIR. Continue (y/n)?" choice
case "$choice" in
  y|Y ) rm -rf $OVS_RUNDIR/*; echo "Deletion complete";;
  n|N ) echo "Aborted";;
  * ) echo "Invalid, aborting";;
esac

set -x

pkill ovs-vswitchd
pkill ovsdb-server
pkill ovn-controller
pkill ovn-northd

ip netns del ovs-main
ip netns del ovs-second

ip link del alice0
ip link del bob0
ip link del carol0
ip netns del alice
ip netns del bob
ip netns del carol
