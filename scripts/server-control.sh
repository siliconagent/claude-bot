#!/bin/bash
# server-control.sh - Server lifecycle management for testing

set -e

SERVER_STATE="${STATE_DIR:-.claude}/claude-bot.servers.yaml"
SCREENSHOTS_DIR="${STATE_DIR:-.claude}/screenshots"

# Initialize server state
server-init() {
    if [[ ! -f "$SERVER_STATE" ]]; then
        mkdir -p "$(dirname "$SERVER_STATE")"
        cat > "$SERVER_STATE" << 'EOF'
# Server State for Claude-Bot
version: "2.0"
servers: []
EOF
    fi
    mkdir -p "$SCREENSHOTS_DIR"
}

# Detect dev server command from package.json
# Usage: server-detect
server-detect() {
    if [[ ! -f "package.json" ]]; then
        echo "No package.json found"
        return 1
    fi

    # Check for common dev server scripts
    local scripts
    scripts=$(grep -A 20 '"scripts"' package.json | grep -oE '"(dev|start|serve|preview)":[^,]+'" || true)

    echo "Detected server scripts:"
    echo "$scripts"

    # Prioritize: dev > start > serve > preview
    for script_name in dev start serve preview; do
        if echo "$scripts" | grep -q "\"$script_name\""; then
            echo "Recommended: npm run $script_name"
            return 0
        fi
    done
}

# Detect server port
# Usage: server-port
server-port() {
    local default_port=3000

    # Check package.json for --port or -p flags
    if [[ -f "package.json" ]]; then
        local port
        port=$(grep -oE '\-\-port [0-9]+|-p [0-9]+' package.json | head -1 | awk '{print $2}' || echo "$default_port")
        echo "$port"
    else
        echo "$default_port"
    fi
}

# Start server in background
# Usage: server-start [worktree_path]
server-start() {
    local worktree_path="${1:-.}"

    server-init

    # Detect server command
    local server_cmd
    server_cmd=$(server-detect | grep "Recommended:" | awk '{print $3}' || echo "npm run dev")

    if [[ -z "$server_cmd" ]]; then
        echo "No server command detected"
        return 1
    fi

    # Detect port
    local port
    port=$(server-port)

    local server_id="server-$(date +%s)"
    local pid_file="${STATE_DIR:-.claude}/server.${server_id}.pid"
    local log_file="${STATE_DIR:-.claude}/server.${server_id}.log"

    # Start server in background
    echo "Starting server: $server_cmd in $worktree_path"
    (cd "$worktree_path" && nohup $server_cmd > "$log_file" 2>&1 & echo $! > "$pid_file")

    # Wait for server to be ready
    local max_wait=30
    local waited=0

    while [[ $waited -lt $max_wait ]]; do
        if curl -s "http://localhost:$port" >/dev/null 2>&1; then
            break
        fi
        sleep 1
        waited=$((waited + 1))
    done

    if [[ $waited -ge $max_wait ]]; then
        echo "Server failed to start within ${max_wait}s"
        return 1
    fi

    local pid
    pid=$(cat "$pid_file")

    # Register server
    cat >> "$SERVER_STATE" << EOF

  - id: $server_id
    pid: $pid
    command: $server_cmd
    port: $port
    worktree: $worktree_path
    status: running
    started_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ready_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
    logs: $log_file
    health_check_url: http://localhost:$port
EOF

    echo "Server started: $server_id"
    echo "  PID: $pid"
    echo "  Port: $port"
    echo "  Logs: $log_file"
}

# Wait for server to be ready
# Usage: server-wait [timeout]
server-wait() {
    local timeout="${1:-30}"
    local port
    port=$(server-port)

    echo "Waiting for server (timeout: ${timeout}s)..."

    local waited=0
    while [[ $waited -lt $timeout ]]; do
        if curl -s "http://localhost:$port" >/dev/null 2>&1; then
            echo "Server is ready!"
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done

    echo "Server not ready after ${timeout}s"
    return 1
}

# Check if server is running
# Usage: server-status [server_id]
server-status() {
    local server_id="${1:-}"

    server-init

    if [[ -n "$server_id" ]]; then
        grep -A 10 "id: $server_id" "$SERVER_STATE" || {
            echo "Server not found: $server_id"
            return 1
        }
    else
        echo "# All Servers"
        grep -A 12 "^  - id:" "$SERVER_STATE" | \
            awk '
                /id:/ {
                    id = $2
                    printf "  %s\n", id
                }
                /pid:/ {
                    printf "    PID: %s\n", $2
                }
                /port:/ {
                    printf "    Port: %s\n", $2
                }
                /status:/ {
                    printf "    Status: %s\n", $2
                }
                /^  - id:/ {
                    printf "\n"
                }
            '
    fi
}

# Get server port
# Usage: server-get-port [server_id]
server-get-port() {
    local server_id="${1:-}"

    server-init

    if [[ -n "$server_id" ]]; then
        grep -A 10 "id: $server_id" "$SERVER_STATE" | grep "port:" | awk '{print $2}'
    else
        # Get most recently started server
        grep "port:" "$SERVER_STATE" | tail -1 | awk '{print $2}'
    fi
}

# Stop server
# Usage: server-stop [server_id]
server-stop() {
    local server_id="${1:-}"

    server-init

    if [[ -z "$server_id" ]]; then
        # Stop most recently started server
        server_id=$(grep "^  - id:" "$SERVER_STATE" | tail -1 | awk '{print $2}')
    fi

    if [[ -z "$server_id" ]]; then
        echo "No server to stop"
        return 1
    fi

    # Get PID
    local pid
    pid=$(grep -A 5 "id: $server_id" "$SERVER_STATE" | grep "pid:" | awk '{print $2}')

    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null || true
        echo "Stopped server $server_id (PID: $pid)"
    fi

    # Remove from state
    awk "
        /id: $server_id/ { skip = 1 }
        skip && /^  - id:/ && !/id: $server_id/ { skip = 0 }
        !skip { print }
    " "$SERVER_STATE" > "${SERVER_STATE}.tmp" && mv "${SERVER_STATE}.tmp" "$SERVER_STATE"
}

# Get server logs
# Usage: server-logs [server_id] [tail_lines]
server-logs() {
    local server_id="${1:-}"
    local tail_lines="${2:-50}"

    server-init

    if [[ -z "$server_id" ]]; then
        server_id=$(grep "^  - id:" "$SERVER_STATE" | tail -1 | awk '{print $2}')
    fi

    local log_file
    log_file=$(grep -A 10 "id: $server_id" "$SERVER_STATE" | grep "logs:" | awk '{print $2}')

    if [[ -n "$log_file" && -f "$log_file" ]]; then
        tail -n "$tail_lines" "$log_file"
    else
        echo "No logs found for server $server_id"
    fi
}

# Capture screenshot
# Usage: server-screenshot [server_id] [filename]
server-screenshot() {
    local server_id="${1:-}"
    local filename="${2:-screenshot-$(date +%s).png}"

    server-init

    local port
    port=$(server-get-port "$server_id")

    if [[ -z "$port" ]]; then
        echo "Cannot determine server port"
        return 1
    fi

    # Use playwright MCP to capture screenshot
    echo "Capturing screenshot from http://localhost:$port"

    # Note: This would use the Playwright MCP integration
    # For now, just record the intent
    cat >> "$SERVER_STATE" << EOF

screenshot:
  server: $server_id
  url: http://localhost:$port
  file: $SCREENSHOTS_DIR/$filename
  captured_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

    echo "Screenshot would be saved to: $SCREENSHOTS_DIR/$filename"
}

# Main command router
case "${1:-}" in
    init)       server-init ;;
    detect)     server-detect ;;
    port)       server-port ;;
    start)      server-start "$2" ;;
    wait)       server-wait "${2:-30}" ;;
    status)     server-status "${2:-}" ;;
    get-port)   server-get-port "$2" ;;
    stop)       server-stop "$2" ;;
    logs)       server-logs "$2" "${3:-50}" ;;
    screenshot) server-screenshot "$2" "$3" ;;
    *)
        echo "Usage: $0 {init|detect|port|start|wait|status|get-port|stop|logs|screenshot}"
        exit 1
        ;;
esac
