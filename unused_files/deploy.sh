#!/bin/bash

# Script para desplegar el sistema completo de control de acceso con encriptación cuántica

echo "Desplegando el sistema de control de acceso con encriptación cuántica"

# Crear namespace
echo "Creando namespace..."
kubectl apply -f k8s/namespace.yaml

# Crear configmaps globales
echo "Creando configuraciones globales..."
kubectl apply -f k8s/configmap.yaml

# Desplegar almacenamiento
echo "Desplegando bases de datos..."
kubectl apply -f k8s/storage/

# Esperar a que las bases de datos estén listas
echo "Esperando a que las bases de datos estén listas..."
kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n quantum-access-control
kubectl wait --for=condition=available --timeout=300s deployment/elasticsearch -n quantum-access-control

# Desplegar capa de Cloud Processing
echo "Desplegando capa de cloud processing..."
kubectl apply -f k8s/cloud-processing/orion-deployment.yaml
kubectl apply -f k8s/cloud-processing/orion-service.yaml
kubectl apply -f k8s/cloud-processing/nifi-deployment.yaml
kubectl apply -f k8s/cloud-processing/nifi-service.yaml
kubectl apply -f k8s/cloud-processing/draco-deployment.yaml
kubectl apply -f k8s/cloud-processing/draco-service.yaml

# Esperar a que los servicios cloud estén listos
echo "Esperando a que los servicios cloud estén listos..."
echo "Este proceso puede tardar hasta 10 minutos en una Raspberry Pi..."
kubectl wait --for=condition=available --timeout=600s deployment/orion-context-broker -n quantum-access-control || true
kubectl wait --for=condition=available --timeout=600s deployment/apache-nifi -n quantum-access-control || true
kubectl wait --for=condition=available --timeout=600s deployment/draco -n quantum-access-control || true

# Crear suscripciones
echo "Creando suscripciones..."
kubectl apply -f k8s/cloud-processing/create-subscriptions-job.yaml

# Desplegar edge server (Raspberry Pi)
echo "Desplegando edge server (Raspberry Pi)..."
kubectl apply -f k8s/edge-server/

# Esperar a que el edge server esté listo
echo "Esperando a que el edge server esté listo..."
kubectl wait --for=condition=available --timeout=300s deployment/raspberry-pi-gateway -n quantum-access-control

# Desplegar edge device (ESP32 + RFID)
echo "Desplegando edge device (ESP32 + RFID)..."
kubectl apply -f k8s/edge-device/

# Desplegar monitoreo
echo "Desplegando monitoreo (Prometheus y Grafana)..."
kubectl apply -f k8s/monitoring/prometheus/
kubectl apply -f k8s/monitoring/grafana/

# Desplegar ingress
echo "Desplegando ingress..."
kubectl apply -f k8s/ingress.yaml

# Mostrar información para acceder al sistema
echo "============================================================="
echo "Sistema de control de acceso con encriptación cuántica desplegado!"
echo "============================================================="
echo "Agrega la siguiente línea a tu archivo /etc/hosts:"
echo "127.0.0.1 quantum-access.local"
echo "============================================================="
echo "Accesos a servicios:"
echo "- Orion Context Broker: http://quantum-access.local/orion"
echo "- Apache NiFi: http://quantum-access.local/nifi"
echo "- Draco: http://quantum-access.local/draco"
echo "- Grafana: http://quantum-access.local/grafana (admin/admin)"
echo "- Prometheus: http://quantum-access.local/prometheus"
echo "============================================================="
