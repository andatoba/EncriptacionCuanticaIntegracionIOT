#!/bin/bash

# Script para verificar el estado actual del despliegue y continuar
echo "=== Verificando estado actual del despliegue ==="

# Verificar el estado de los pods
echo "Estado actual de los pods:"
kubectl get pods -n quantum-access-control

# Continuar con el despliegue de MQTT (paso 4)
echo -e "\n4. Desplegando broker MQTT..."
kubectl apply -f k8s/edge-server/mosquitto-config.yaml
kubectl apply -f k8s/edge-server/mqtt-service.yaml
sleep 5
kubectl get pods -n quantum-access-control -l app=mqtt-broker

# Desplegar Orion Context Broker (optimizado para Raspberry Pi)
echo -e "\n5. Desplegando Orion Context Broker con recursos reducidos..."
# Aplicar parche para reducir recursos de Orion
kubectl apply -f k8s/cloud-processing/orion-deployment.yaml
kubectl patch deployment orion-context-broker -n quantum-access-control -p '{"spec":{"template":{"spec":{"containers":[{"name":"orion","resources":{"limits":{"memory":"256Mi","cpu":"200m"},"requests":{"memory":"128Mi","cpu":"100m"}}}]}}}}'
kubectl apply -f k8s/cloud-processing/orion-service.yaml
sleep 5
kubectl get pods -n quantum-access-control -l app=orion

# Desplegar procesador cuántico en la Raspberry Pi con dependencias pre-instaladas
echo -e "\n6. Desplegando procesador cuántico con dependencias..."
kubectl apply -f k8s/edge-server/raspberry-pi-deployment.yaml
kubectl patch deployment raspberry-pi-gateway -n quantum-access-control -p '{"spec":{"template":{"spec":{"containers":[{"name":"quantum-processor","command":["sh","-c","pip install numpy paho-mqtt requests && python -u /app/quantum_processor.py"]}]}}}}'
sleep 5
kubectl get pods -n quantum-access-control -l app=raspberry-pi-gateway

# Desplegar monitor de rendimiento con dependencias pre-instaladas
echo -e "\n7. Desplegando monitor de rendimiento con dependencias..."
kubectl apply -f k8s/monitoring/performance-monitor.yaml
kubectl patch deployment performance-monitor -n quantum-access-control -p '{"spec":{"template":{"spec":{"containers":[{"name":"performance-monitor","command":["sh","-c","pip install prometheus_client && python -u /app/performance_monitor.py"]}]}}}}'
sleep 5
kubectl get pods -n quantum-access-control -l app=performance-monitor

# Mostrar estado final
echo -e "\n=== Estado final del despliegue ==="
kubectl get pods -n quantum-access-control

echo -e "\n=== Soluciones para pods en CrashLoopBackOff ==="
echo "Si algún pod está en CrashLoopBackOff, puedes revisar los logs con:"
echo "kubectl logs -n quantum-access-control <nombre-del-pod>"
echo ""
echo "Para reiniciar un pod:"
echo "kubectl delete pod -n quantum-access-control <nombre-del-pod>"
echo ""
echo "Para verificar los recursos disponibles en la Raspberry Pi:"
echo "kubectl describe nodes"
