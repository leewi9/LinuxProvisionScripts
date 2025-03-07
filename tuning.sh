#!/bin/bash

# Exit on any error
set -e

###########################################
# Functions
###########################################

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: This script must be run as root"
        exit 1
    fi
}

check_dependencies() {
    if ! command -v bc >/dev/null 2>&1; then
        echo "Installing bc package..."
        apt-get update && apt-get install -y bc
    fi
}

backup_configs() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    echo "Creating backups with timestamp: $timestamp"
    
    for file in "/etc/sysctl.conf" "/etc/security/limits.conf"; do
        if [ -f "$file" ]; then
            cp "$file" "${file}.bak_${timestamp}"
            echo "Backed up $file to ${file}.bak_${timestamp}"
        fi
    done
}

calculate_values() {
    # Get total memory in bytes
    mem_bytes=$(awk '/MemTotal:/ { printf "%0.f",$2 * 1024}' /proc/meminfo)
    
    # Allow up to 50% of RAM for shared memory (usually plenty)
    shmmax=$(echo "$mem_bytes * 0.50" | bc | cut -f 1 -d '.')
    shmall=$(expr $shmmax / $(getconf PAGE_SIZE))
    
    # More generous file handle calculation
    # Base value of 256k files plus extra based on RAM
    # Modern systems can easily handle these limits
    base_files=262144  # increased from 65536
    mem_gb=$(echo "$mem_bytes / 1073741824" | bc)
    file_max=$(echo "$base_files + ($mem_gb * 32768)" | bc | cut -f 1 -d '.') # increased multiplier

    # Keep 5% of RAM as minimum free, but cap at 256MB
    min_free_kb=$(echo "($mem_bytes / 1024) * 0.05" | bc | cut -f 1 -d '.')
    if [ $min_free_kb -gt 262144 ]; then
        min_free_kb=262144
    fi
    min_free=$min_free_kb
    
    echo "System memory: ${mem_gb}GB"
    echo "Calculated values:"
    echo "- shmmax: $shmmax (~$(echo "$shmmax / 1073741824" | bc)GB)"
    echo "- shmall: $shmall pages"
    echo "- file_max: $file_max files"
    echo "- min_free: $min_free KB (~$(echo "$min_free / 1024" | bc)MB)"
}

update_limits_conf() {
    echo "Updating /etc/security/limits.conf..."
    local new_limits
    new_limits=$(cat <<'EOF'
# /etc/security/limits.conf
# Generated by tuning.sh
*    soft    nofile    __FILE_MAX__
*    hard    nofile    __FILE_MAX__
*    soft    nproc     __FILE_MAX__
*    hard    nproc     __FILE_MAX__
# in order to change the limits for root user as well, it must be added explicitly:
root soft    nofile    __FILE_MAX__
root hard    nofile    __FILE_MAX__
root soft    nproc     __FILE_MAX__
root hard    nproc     __FILE_MAX__
EOF
    )
    # Replace the placeholder with the current file_max value.
    new_limits="${new_limits//__FILE_MAX__/$file_max}"
    
    if [ -f /etc/security/limits.conf ]; then
        if diff <(echo "$new_limits") /etc/security/limits.conf >/dev/null; then
            echo "/etc/security/limits.conf is already up-to-date."
            return
        fi
    fi
    cat > /etc/security/limits.conf <<< "$new_limits"
    echo "/etc/security/limits.conf updated."
}

update_sysctl_conf() {
    echo "Updating /etc/sysctl.conf..."
    local new_sysctl
    new_sysctl=$(cat <<'EOF'
# /etc/sysctl.conf
# Generated by tuning.sh

### IMPROVE SYSTEM MEMORY MANAGEMENT ###

# Increase size of file handles and inode cache
fs.file-max = __FILE_MAX__

# Decrease swap usage to a more reasonable level
# * 0: swap is disable
# * 1: minimum amount of swapping without disabling it entirely
# * 10: recommended value to improve performance when sufficient memory exists in a system
# * 100: aggressive swapping
vm.swappiness = 10

# Shared Memory Settings
kernel.shmmax = __SHMMAX__
kernel.shmall = __SHMALL__

# Keep minimum free RAM space available
vm.min_free_kbytes = __MIN_FREE__

### NETWORK PERFORMANCE TUNING ###

# Increase system-wide socket buffer limits
# Max socket receive buffer (16MB)
net.core.rmem_max = 16777216
# Max socket send buffer (16MB)
net.core.wmem_max = 16777216
# Default socket receive buffer (1MB)
net.core.rmem_default = 1048576
# Default socket send buffer (1MB)
net.core.wmem_default = 1048576
# Max backlog queue size
net.core.somaxconn = 65536
# Max number of packets queued
net.core.netdev_max_backlog = 32768

### TCP OPTIMIZATIONS ###
# TCP buffer sizes (min, default, max in bytes)
net.ipv4.tcp_rmem = 4096 1048576 16777216
net.ipv4.tcp_wmem = 4096 1048576 16777216

# TCP connection handling
net.ipv4.tcp_max_syn_backlog = 32768
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_slow_start_after_idle = 0

# TCP keepalive settings
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5

# TCP memory limits
net.ipv4.tcp_mem = 786432 1048576 1572864

# TCP performance features
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1

### IPv4 NETWORK SECURITY ###
# Enable SYN flood protection
net.ipv4.tcp_syncookies = 1
# Protect against time-wait assassination
net.ipv4.tcp_rfc1337 = 1
# Reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

### GENERAL NETWORK SECURITY ###
# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
EOF
    )
    new_sysctl="${new_sysctl//__FILE_MAX__/$file_max}"
    new_sysctl="${new_sysctl//__SHMMAX__/$shmmax}"
    new_sysctl="${new_sysctl//__SHMALL__/$shmall}"
    new_sysctl="${new_sysctl//__MIN_FREE__/$min_free}"

    if [ -f /etc/sysctl.conf ]; then
        if diff <(echo "$new_sysctl") /etc/sysctl.conf >/dev/null; then
            echo "/etc/sysctl.conf is already up-to-date."
            return
        fi
    fi
    cat > /etc/sysctl.conf <<< "$new_sysctl"
    echo "/etc/sysctl.conf updated."
}

update_systemd_limits() {
    echo "Updating systemd limits..."
    local updated=0
    
    if [ -d /etc/systemd/system.conf.d ]; then
        local new_system
        new_system=$(cat <<EOF
[Manager]
DefaultLimitNOFILE=$file_max
EOF
        )
        if [ -f /etc/systemd/system.conf.d/limits.conf ]; then
            if diff <(echo "$new_system") /etc/systemd/system.conf.d/limits.conf >/dev/null; then
                echo "/etc/systemd/system.conf.d/limits.conf is already up-to-date."
            else
                cat > /etc/systemd/system.conf.d/limits.conf <<< "$new_system"
                updated=1
            fi
        else
            cat > /etc/systemd/system.conf.d/limits.conf <<< "$new_system"
            updated=1
        fi
    else
        echo "Directory /etc/systemd/system.conf.d does not exist, skipping system-wide limits update."
    fi

    if [ -d /etc/systemd/user.conf.d ]; then
        local new_user
        new_user=$(cat <<EOF
[Manager]
DefaultLimitNOFILE=$file_max
EOF
        )
        if [ -f /etc/systemd/user.conf.d/limits.conf ]; then
            if diff <(echo "$new_user") /etc/systemd/user.conf.d/limits.conf >/dev/null; then
                echo "/etc/systemd/user.conf.d/limits.conf is already up-to-date."
            else
                cat > /etc/systemd/user.conf.d/limits.conf <<< "$new_user"
                updated=1
            fi
        else
            cat > /etc/systemd/user.conf.d/limits.conf <<< "$new_user"
            updated=1
        fi
    else
        echo "Directory /etc/systemd/user.conf.d does not exist, skipping user limits update."
    fi
     
    if [ "$updated" -eq 1 ]; then
        echo "Systemd limits updated. A reboot is recommended for these changes to take effect."
    fi
}

apply_changes() {
    echo "Applying sysctl changes..."
    sysctl -p /etc/sysctl.conf
    
    echo "Changes applied successfully!"
    echo "Note: Some changes may require a system reboot to take full effect"
}

###########################################
# Main Script
###########################################

main() {
    echo "Starting system tuning..."
    
    check_root
    check_dependencies
    backup_configs
    calculate_values
    update_limits_conf
    update_systemd_limits
    update_sysctl_conf
    apply_changes
    
    echo "System tuning completed successfully!"
}

# Run main function
main



