#!/usr/bin/env python3
import getpass
import shutil
import subprocess
import sys
import os

server = os.getenv('SPIRALCOIN_SERVER', 'root@174.138.37.6')
password = os.getenv('SPIRALCOIN_SSH_PASSWORD') or getpass.getpass(
    f"SSH password for {server}: "
)

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
use_sshpass = shutil.which('sshpass') is not None
cmd = ' && '.join(commands)

if use_sshpass:
    print("Using sshpass for authentication...")
    full_cmd = ['sshpass', '-p', password, 'ssh', '-o', 'StrictHostKeyChecking=no', server, cmd]
else:
    print("sshpass not found. Attempting direct SSH (you may need to enter password manually)...")
    full_cmd = ['ssh', '-o', 'StrictHostKeyChecking=no', server, cmd]

subprocess.run(full_cmd)
