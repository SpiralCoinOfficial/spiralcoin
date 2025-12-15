#!/usr/bin/env python3
import subprocess
import sys
import os

password = 'HarLand2025a!'
server = 'root@174.138.37.6'

# Set up environment
os.environ['SSHPASS'] = password

# Commands to execute
commands = [
    'echo "=== Connected to server ==="',
    'curl -fsSL https://get.docker.com | sh',
    'cd /root && rm -rf spiralcoin && git clone https://github.com/SpiralCoinOfficial/spiralcoin.git',
    'cd /root/spiralcoin && docker compose up -d --build 2>&1 | tail -30',
    'echo "=== Services Status ===" && docker compose ps'
]

# Try sshpass first, fallback to manual password entry
try:
    # Check if sshpass exists
    subprocess.run(['where', 'sshpass'], check=True, capture_output=True)
    use_sshpass = True
except:
    use_sshpass = False

if use_sshpass:
    print("Using sshpass for authentication...")
    cmd = ' && '.join(commands)
    full_cmd = ['sshpass', '-p', password, 'ssh', '-o', 'StrictHostKeyChecking=no', server, cmd]
    subprocess.run(full_cmd)
else:
    print("sshpass not found. Attempting direct SSH (you may need to enter password manually)...")
    cmd = ' && '.join(commands)
    full_cmd = ['ssh', '-o', 'StrictHostKeyChecking=no', server, cmd]
    subprocess.run(full_cmd)
