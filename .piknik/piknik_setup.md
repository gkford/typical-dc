# Setting Up Piknik for Clipboard Sharing Between Devcontainer and Mac

This guide explains how to set up Piknik for clipboard synchronization between an Ubuntu Jammy devcontainer and your Mac.

## Devcontainer Configuration

### VSCode Extensions

Add the Piknik extension to your `.devcontainer.json`:

```json
"customizations": {
  "vscode": {
    "extensions": [
      "esbenp.prettier-vscode",
      "ms-python.python",
      "ms-toolsai.jupyter",
      "jedisct1.piknik"
    ]
  }
},
```

### Confirm Automated Setup

Check your existing `.devcontainer/postCreate.sh` script to ensure it includes these required Piknik-related commands. Your postCreate script likely already has most or all of these, but verify that it handles:

```bash
# Piknik installation
wget https://github.com/jedisct1/piknik/releases/download/0.10.2/piknik-linux_x86_64-0.10.2.tar.gz
tar xzf piknik-linux_x86_64-0.10.2.tar.gz
sudo mv linux-x86_64/piknik /usr/local/bin/piknik
sudo chmod +x /usr/local/bin/piknik
rm -rf piknik-linux_x86_64-0.10.2.tar.gz linux-x86_64

# Required dependencies and X server setup
sudo apt-get update
sudo apt-get install xclip -y
sudo apt-get install xvfb -y
sudo apt-get install inotify-tools -y

# Virtual framebuffer setup
sudo Xvfb :99 -screen 0 1024x768x16 &

# DISPLAY environment setup
if ! grep -q "export DISPLAY=:99" ~/.bashrc; then
    echo "export DISPLAY=:99" >> ~/.bashrc
fi
export DISPLAY=:99
```

These commands are typically included in a standard development container setup, particularly if you're using tools like aider that require clipboard access. If any are missing, add them to your existing postCreate.sh script.

## Manual Installation on the Devcontainer

### 1. Download and Install Piknik

Run the following commands in your devcontainer terminal:

```bash
wget https://github.com/jedisct1/piknik/releases/download/0.10.2/piknik-linux_x86_64-0.10.2.tar.gz
tar xzf piknik-linux_x86_64-0.10.2.tar.gz
sudo mv linux-x86_64/piknik /usr/local/bin/piknik
sudo chmod +x /usr/local/bin/piknik
rm -rf piknik-linux_x86_64-0.10.2.tar.gz linux-x86_64
```

### 2. Install Dependencies

```bash
sudo apt-get update
sudo apt-get install xclip -y
sudo apt-get install xvfb -y
sudo apt-get install inotify-tools -y
```

### 3. Start a Virtual Framebuffer

```bash
sudo Xvfb :99 -screen 0 1024x768x16
export DISPLAY=:99
```

### 4. Create and Run the Combined Server and Clipboard Sender

Create a file named `run_piknik_server.sh` with the following content:

```bash
#!/bin/bash
export DISPLAY=:99

# Function to cleanup background processes on script exit
cleanup() {
    echo "Stopping Piknik server and clipboard sender..."
    pkill -P $  # Kill all child processes
    exit 0
}

# Set up trap to catch script termination
trap cleanup SIGINT SIGTERM

# Start Piknik server in background with output
echo "Starting Piknik server..."
piknik -server > >(while read line; do echo "[Server] $line"; done) 2>&1 &

echo "Starting clipboard sender..."
# Previous clipboard content
LAST_CLIPBOARD=""

# Clipboard sender loop
while true; do
    # Get current clipboard content
    CLIPBOARD=$(xclip -o -selection clipboard 2>/dev/null || echo "")
    
    # Check if the clipboard content has changed
    if [[ "$CLIPBOARD" != "$LAST_CLIPBOARD" ]]; then
        echo "[Sender] Copying new content to Piknik"
        echo "$CLIPBOARD" | piknik -copy
        LAST_CLIPBOARD="$CLIPBOARD"
    fi
    
    # Wait before checking again
    sleep 0.5
done
```

Make it executable:

```bash
chmod +x run_piknik_server.sh
```

Run it in a dedicated terminal tab/window:

```bash
./run_piknik_server.sh
```

The script will now run both the Piknik server and clipboard sender in the same terminal with labeled output. You can:
- See server activity with "[Server]" prefix
- See clipboard sender activity with "[Sender]" prefix
- Stop both processes at once with Ctrl+C

Pro tip: Run this in a dedicated VS Code terminal tab to keep it visible and easily manageable.

## Setting Up Piknik on Your Mac

### 1. Install Piknik

Download Piknik for macOS from the [Piknik Releases page](https://github.com/jedisct1/piknik/releases/latest)

### 2. Create the Clipboard Receiver Script

Create a file named `clipboard_receiver.sh` with the following content:

```bash
#!/bin/bash

# Trap Ctrl+C (SIGINT) to exit cleanly
trap 'echo -e "\nStopping clipboard receiver..."; exit 0' SIGINT

echo "Starting clipboard receiver..."
echo "Press Ctrl+C to stop"
echo "------------------------"

# Store the last clipboard content retrieved from Piknik
LAST_PIKNIK_CLIPBOARD=""

while true; do
    # Get the clipboard content from Piknik
    NEW_CLIPBOARD=$(piknik -paste 2>/dev/null)  # Suppress error messages
    
    # Check if the Piknik clipboard has changed
    if [[ "$NEW_CLIPBOARD" != "$LAST_PIKNIK_CLIPBOARD" && ! -z "$NEW_CLIPBOARD" ]]; then
        echo "New clipboard content received!"
        # Update the Mac's clipboard
        echo "$NEW_CLIPBOARD" | pbcopy
        # Update the local variable to track the last clipboard content
        LAST_PIKNIK_CLIPBOARD="$NEW_CLIPBOARD"
    fi
    
    # Wait before checking again
    sleep 0.5
done
```

Make it executable:

```bash
chmod +x clipboard_receiver.sh
```

Run it in a dedicated terminal window:

```bash
./clipboard_receiver.sh
```

The script will now run in the foreground and show its activity. You can:
- See when new clipboard content is received
- Stop it at any time with Ctrl+C
- Keep track of its status in the terminal window

Pro tip: Keep this terminal window visible (but minimized if you prefer) so you always know when the clipboard sync is active.

## Configuration for Piknik

### 1. Generate Keys

On the devcontainer, generate keys using:

```bash
piknik -genkeys
```

Use the output to configure `.piknik.toml`.

### 2. Example Configuration File on Mac

Create a `.piknik.toml` file with the following content:

```toml
Listen = "localhost:8075"
Psk    = "xxx"
SignPk = "xxx"
SignSk = "xxx"
EncryptSk = "xxx"
```

Note: Replace the keys with your own generated keys.

### 3. Forward Required Ports in Devcontainer

Add the following to your `.devcontainer.json`:

```json
"forwardPorts": [4040, 8075]
```

## Notes

- This guide assumes the Piknik server runs on the devcontainer. Adjust as needed for your setup.
- Clipboard synchronization is one-way: from the devcontainer to the Mac. Copy-pasting on the Mac works as usual without affecting the devcontainer clipboard.