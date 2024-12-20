#!/bin/bash
#
# curl https://raw.githubusercontent.com/marcelofmatos/docker-swarm/refs/heads/main/scripts/diagnostics.sh | bash
#
#!/bin/bash

VERBOSE=0

if [[ "$1" == "--verbose" ]]; then
  VERBOSE=1
fi

echo "### Docker Swarm Diagnostic Script ###"

# Function to display status
show_status() {
  local message=$1
  local status=$2
  if [[ "$status" -eq 0 ]]; then
    echo -e "[\033[32mOK\033[0m] $message"
  else
    echo -e "[\033[31mError\033[0m] $message"
  fi
}

# Test 1: Connectivity to the manager
echo "Test 1: Connectivity to the Manager"
MANAGER_IP="10.0.0.175"
ping -c 1 $MANAGER_IP > /dev/null 2>&1
show_status "Connectivity to manager ($MANAGER_IP)" $?

# Test 2: Check port 2377
echo "Test 2: Port 2377 on Manager"
nc -zv $MANAGER_IP 2377 > /tmp/port_test.log 2>&1
if [[ $? -eq 0 ]]; then
  show_status "Port 2377 is accessible on the manager" 0
else
  show_status "Port 2377 is not accessible on the manager" 1
  echo "Evidence: $(cat /tmp/port_test.log)"
fi

# Test 3: Check Docker version
echo "Test 3: Check Docker version"
DOCKER_VERSION=$(docker version --format '{{.Server.Version}}')
if [[ $? -eq 0 ]]; then
  show_status "Docker is installed (version: $DOCKER_VERSION)" 0
else
  show_status "Docker is not installed or not configured properly" 1
fi

# Test 4: Check node status in Swarm
echo "Test 4: Check node status in Swarm"
SWARM_STATUS=$(docker info --format '{{.Swarm.LocalNodeState}}')
if [[ "$SWARM_STATUS" == "active" ]]; then
  show_status "Node is active in Swarm" 0
else
  show_status "Node is not active in Swarm (Status: $SWARM_STATUS)" 1
fi

# Test 5: Time synchronization
echo "Test 5: Time synchronization"
TIME_SYNC=$(timedatectl | grep "clock synchronized" | grep -o "yes")
if [[ "$TIME_SYNC" == "yes" ]]; then
  show_status "Time is synchronized with NTP" 0
else
  show_status "Time is not synchronized with NTP" 1
fi

# Test 6: Docker logs access
echo "Test 6: Check Docker logs"
CONTAINER_IDS=$(docker ps -q)

if [[ -n "$CONTAINER_IDS" ]]; then
  LOG_DIR="/tmp/docker_logs"
  mkdir -p $LOG_DIR
  for CONTAINER_ID in $CONTAINER_IDS; do
    docker logs $CONTAINER_ID > "$LOG_DIR/$CONTAINER_ID.log" 2>&1
    if [[ $? -eq 0 ]]; then
      show_status "Logs for container $CONTAINER_ID saved to $LOG_DIR/$CONTAINER_ID.log" 0
    else
      show_status "Failed to fetch logs for container $CONTAINER_ID" 1
      echo "Evidence: $(tail -n 5 $LOG_DIR/$CONTAINER_ID.log)"
    fi
  done
else
  show_status "No running containers found" 1
fi

