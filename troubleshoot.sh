#!/bin/bash

# Script to troubleshoot K3s issues and deploy the quantum access control system
echo "=== Troubleshooting K3s and deploying quantum access control system ==="

# Check K3s status
echo "Checking K3s service status..."
sudo systemctl status k3s

# Restart K3s if needed
echo "Restarting K3s service..."
sudo systemctl restart k3s
sleep 10

# Set proper permissions for kubeconfig
echo "Setting proper kubeconfig permissions..."
sudo chmod 644 /etc/rancher/k3s/k3s.yaml

# Create a copy of the kubeconfig for the current user
echo "Creating user-specific kubeconfig..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
export KUBECONFIG=~/.kube/config

# Ensure connection to the API server
echo "Checking connection to Kubernetes API server..."
kubectl get nodes

# Delete namespace if it exists
echo "Cleaning up previous deployment..."
kubectl delete namespace quantum-access-control --ignore-not-found=true
sleep 5

# Create namespace with validation disabled
echo "Creating namespace..."
kubectl apply -f k8s/namespace.yaml --validate=false

# Apply configuration
echo "Creating configurations..."
kubectl apply -f k8s/configmap.yaml --validate=false

# Deploy storage components
echo "Deploying MongoDB..."
kubectl apply -f k8s/storage/mongodb-pvc.yaml --validate=false
kubectl apply -f k8s/storage/mongodb-deployment.yaml --validate=false
kubectl apply -f k8s/storage/mongodb-service.yaml --validate=false

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to start (this may take a minute)..."
kubectl wait --for=condition=ready pod -l app=mongodb -n quantum-access-control --timeout=120s

# Deploy the Orion Context Broker
echo "Deploying Orion Context Broker..."
kubectl apply -f k8s/cloud-processing/orion-deployment.yaml --validate=false
kubectl apply -f k8s/cloud-processing/orion-service.yaml --validate=false

# Deploy the MQTT broker for edge devices
echo "Deploying MQTT broker..."
kubectl apply -f k8s/edge-server/mosquitto-config.yaml --validate=false
kubectl apply -f k8s/edge-server/mqtt-service.yaml --validate=false

# Deploy the Raspberry Pi gateway with quantum processor
echo "Deploying Raspberry Pi gateway with quantum processor..."
kubectl apply -f k8s/edge-server/raspberry-pi-deployment.yaml --validate=false

# Deploy the monitoring solution
echo "Deploying performance monitoring..."
kubectl apply -f k8s/monitoring/performance-monitor.yaml --validate=false

# Check the deployment status
echo "Checking pod status..."
kubectl get pods -n quantum-access-control

echo "=== Deployment completed ==="
echo "Note: Some pods may take a few minutes to start. Check status with: kubectl get pods -n quantum-access-control"
