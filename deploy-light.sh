#!/bin/bash

# Script de despliegue para entornos con recursos limitados (Raspberry Pi)
echo "Desplegando sistema de control de acceso con encriptación cuántica (modo ligero)"
echo "Este script está optimizado para Raspberry Pi y otros dispositivos con recursos limitados"

# Asegurarse que tenemos acceso a kubectl
export KUBECONFIG=~/.kube/config

# Crear namespace
echo "Creando namespace..."
kubectl apply -f k8s/namespace.yaml
sleep 5

# Crear configmaps
echo "Creando configuraciones globales..."
kubectl apply -f k8s/configmap.yaml
sleep 5

# Desplegar almacenamiento (solo MongoDB)
echo "Desplegando bases de datos (solo MongoDB)..."
kubectl apply -f k8s/storage/mongodb-deployment.yaml
kubectl apply -f k8s/storage/mongodb-service.yaml
kubectl apply -f k8s/storage/mongodb-pvc.yaml
sleep 10

# Esperar a que MongoDB esté listo
echo "Esperando a que MongoDB esté listo..."
kubectl wait --for=condition=ready pod -l app=mongodb -n quantum-access-control --timeout=300s || true
sleep 10

# Desplegar Orion Context Broker
echo "Desplegando Orion Context Broker..."
kubectl apply -f k8s/cloud-processing/orion-deployment.yaml
kubectl apply -f k8s/cloud-processing/orion-service.yaml
sleep 20

# Desplegar edge server (Raspberry Pi)
echo "Desplegando edge server (Raspberry Pi)..."
kubectl apply -f k8s/edge-server/mosquitto-config.yaml
kubectl apply -f k8s/edge-server/raspberry-pi-deployment.yaml
kubectl apply -f k8s/edge-server/mqtt-service.yaml
sleep 30

# Desplegar ingress
echo "Desplegando ingress..."
kubectl apply -f k8s/ingress.yaml
sleep 5

# Verificar estado
echo "Verificando estado de los pods..."
kubectl get pods -n quantum-access-control

echo "============================================================="
echo "Sistema de control de acceso con encriptación cuántica (modo ligero) desplegado!"
echo "============================================================="
echo "Pods principales:"
kubectl get pods -n quantum-access-control
echo "============================================================="
echo "Para ver logs del procesador cuántico:"
echo "kubectl logs -n quantum-access-control -l app=raspberry-pi-gateway -c quantum-processor -f"
echo "============================================================="
