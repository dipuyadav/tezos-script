#!/bin/bash

# Step 0: Check if snapshot file "full" exists in /data, if not, download it
if [ ! -f /data/full ]; then
    echo "Snapshot file 'full' not found. Downloading..."
    wget https://snapshot.tzinit.org/mainnet/full -P /data
else
    echo "Snapshot file 'full' found. Proceeding to next step."
fi

# Step 1: Installing binaries
echo "Downloading and installing Tezos binaries..."
wget -O octez-binaries-20.3-linux-x86_64.tar.gz https://gitlab.com/tezos/tezos/-/package_files/150896058/download
tar -xvf octez-binaries-20.3-linux-x86_64.tar.gz

# Adjust version number if necessary, update if a new version is available
sudo cp octez-x86_64/octez* /usr/local/bin/

# Step 2: Initialize Tezos Node Configuration
echo "Initializing Tezos node configuration..."
mkdir -p /data/tezos-node
cd /data
ln -s /data/tezos-node .tezos-node
octez-node snapshot import /data/full

# Step 3: Install Zcash parameters
echo "Downloading and installing Zcash parameters..."
wget https://raw.githubusercontent.com/zcash/zcash/713fc761dd9cf4c9087c37b078bdeab98697bad2/zcutil/fetch-params.sh
chmod +x fetch-params.sh
./fetch-params.sh

# Step 4: Create and start the Tezos service
echo "Creating Tezos systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/tezos.service
[Unit]
Description=Tezos service
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/data
ExecStart=/usr/local/bin/octez-node run --rpc-addr 0.0.0.0:8732 --metrics-addr 0.0.0.0:9932 --log-output /data/tezos-node/tezos.log --allow-all-rpc 0.0.0.0:8732 --connection 100
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, start service and enable it to start on boot
echo "Starting Tezos service..."
sudo systemctl daemon-reload
sudo systemctl start tezos.service
sudo systemctl enable tezos.service

echo "Tezos setup completed and service is running!"
