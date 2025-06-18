#set -e
declare -a env_vars=(
    "OVN_RUNDIR"
    "OVS_RUNDIR"
    "OVN_DIR"
)

all_vars_set=true

for var_name in "${env_vars[@]}"
do
    if [ -z "${!var_name}" ]; then
        echo "$var_name must be set to proceed."
        all_vars_set=false
    else
        echo "$var_name is set to ${!var_name}"
    fi
done

if [ "$all_vars_set" = true ]; then
    echo "Success: All required environment variables are set."
else
    echo "Failure: One or more required environment variables are not set. Please set them and try again."
    exit 1
fi

set -x

# Export variables to pass them into the following scripts
export OVN_RUNDIR
export OVS_RUNDIR
export OVN_DIR
export PATH=$PATH:$OVN_DIR/utilities/
export PATH=$PATH:$OVN_DIR/northd/
export PATH=$PATH:$OVN_DIR/controller/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
echo "Executing script 1/4..."
sudo -E bash ./stop-everything.sh
echo "Executing script 2/4..."
sudo -E bash four-netns.sh
echo "Executing script 3/4..."
bash -E stateless-lb.sh
echo "Executing script 4/4..."
bash -E 16-steps.sh
