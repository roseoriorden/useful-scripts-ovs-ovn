set -x
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
sudo bash ./stop-everything.sh
sudo bash four-netns.sh
bash stateless-lb.sh
bash 16-steps.sh
