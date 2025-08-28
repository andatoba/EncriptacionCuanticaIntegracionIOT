#!/bin/bash

# Script for deploying quantum access control system on resource-constrained devices
# This script uses the --validate=false flag to bypass API validation issues
# and implements progressive deployment to avoid overwhelming the device

echo "=== Deploying quantum access control system (optimized for Raspberry Pi) ==="

# Configure kubectl to use the correct context
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Create namespace
echo "Creating namespace..."
kubectl apply -f k8s/namespace.yaml --validate=false
sleep 5

# Apply global configurations
echo "Creating configurations..."
kubectl apply -f k8s/configmap.yaml --validate=false
sleep 5

# Deploy MongoDB (core component)
echo "Deploying MongoDB (core database)..."
kubectl apply -f k8s/storage/mongodb-pvc.yaml --validate=false
sleep 2
kubectl apply -f k8s/storage/mongodb-deployment.yaml --validate=false
sleep 2
kubectl apply -f k8s/storage/mongodb-service.yaml --validate=false

# Wait for MongoDB to be ready before continuing
echo "Waiting for MongoDB to be ready (this may take a minute)..."
kubectl wait --for=condition=ready pod -l app=mongodb -n quantum-access-control --timeout=120s --validate=false || true
sleep 15

# Deploy MQTT broker (essential for device communication)
echo "Deploying MQTT broker..."
kubectl apply -f k8s/edge-server/mosquitto-config.yaml --validate=false
kubectl apply -f k8s/edge-server/mqtt-service.yaml --validate=false
sleep 5

# Deploy the quantum processor (core functionality)
echo "Deploying Raspberry Pi gateway with quantum processor..."
kubectl apply -f k8s/edge-server/raspberry-pi-deployment.yaml --validate=false
sleep 10

# Deploy Orion Context Broker (required for data processing)
echo "Deploying Orion Context Broker..."
kubectl apply -f k8s/cloud-processing/orion-deployment.yaml --validate=false
kubectl apply -f k8s/cloud-processing/orion-service.yaml --validate=false
sleep 5

# Deploy performance monitoring (optional but useful)
echo "Deploying performance monitoring..."
# Patch the deployment to install required dependencies
kubectl apply -f k8s/monitoring/performance-monitor.yaml --validate=false

# Display deployment status
echo "=== Deployment Status ==="
kubectl get pods -n quantum-access-control

echo ""
echo "=== Deployment completed ==="
echo "Note: Some pods may take time to start due to resource constraints."
echo "To check status: kubectl get pods -n quantum-access-control"
echo ""
echo "If you encounter pods in CrashLoopBackOff state, try these commands to fix them:"
echo ""
echo "1. For Performance Monitor: kubectl patch deployment performance-monitor -n quantum-access-control -p '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"performance-monitor\",\"command\":[\"sh\",\"-c\",\"pip install prometheus_client && python -u /app/performance_monitor.py\"]}]}}}}'"
echo ""
echo "2. For quantum processor: kubectl patch deployment raspberry-pi-gateway -n quantum-access-control -p '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"quantum-processor\",\"command\":[\"sh\",\"-c\",\"pip install numpy paho-mqtt requests && python -u /app/quantum_processor.py\"]}]}}}}'"
echo ""
echo "3. For Orion Context Broker (if needed): kubectl set resources deployment orion-context-broker -n quantum-access-control --limits=memory=256Mi,cpu=200m --requests=memory=128Mi,cpu=100m"
