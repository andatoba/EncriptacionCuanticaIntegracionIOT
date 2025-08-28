#!/bin/bash

# Script para desplegar de forma progresiva el sistema de control de acceso
# Este script despliega cada componente uno por uno y verifica su estado

echo "=== Despliegue progresivo del sistema de control de acceso con encriptación cuántica ==="

# Comprobar que kubectl está bien configurado
kubectl get nodes > /dev/null
if [ $? -ne 0 ]; then
    echo "ERROR: kubectl no está configurado correctamente"
    echo "Ejecuta los siguientes comandos:"
    echo "export KUBECONFIG=~/.kube/config"
    exit 1
fi

# Crear namespace
echo -e "\n1. Creando namespace..."
kubectl apply -f k8s/namespace.yaml
sleep 3
kubectl get namespace quantum-access-control

# Crear configmap global
echo -e "\n2. Aplicando configuraciones globales..."
kubectl apply -f k8s/configmap.yaml
sleep 3
kubectl get configmap -n quantum-access-control

# Desplegar MongoDB (componente esencial)
echo -e "\n3. Desplegando MongoDB..."
kubectl apply -f k8s/storage/mongodb-pvc.yaml
kubectl apply -f k8s/storage/mongodb-deployment.yaml
kubectl apply -f k8s/storage/mongodb-service.yaml
echo "Esperando a que MongoDB esté listo (puede tardar un minuto)..."
kubectl get pods -n quantum-access-control -l app=mongodb -w
echo "Presiona Ctrl+C cuando el pod de MongoDB esté en estado Running..."
sleep 5

# Desplegar broker MQTT para comunicación con dispositivos
echo -e "\n4. Desplegando broker MQTT..."
kubectl apply -f k8s/edge-server/mosquitto-config.yaml
kubectl apply -f k8s/edge-server/mqtt-service.yaml
sleep 5
kubectl get pods -n quantum-access-control -l app=mqtt-broker

# Desplegar Orion Context Broker (optimizado para Raspberry Pi)
echo -e "\n5. Desplegando Orion Context Broker..."
kubectl apply -f k8s/cloud-processing/orion-deployment.yaml
kubectl apply -f k8s/cloud-processing/orion-service.yaml
sleep 5
kubectl get pods -n quantum-access-control -l app=orion

# Desplegar procesador cuántico en la Raspberry Pi
echo -e "\n6. Desplegando procesador cuántico..."
kubectl apply -f k8s/edge-server/raspberry-pi-deployment.yaml
sleep 5
kubectl get pods -n quantum-access-control -l app=raspberry-pi-gateway

# Si el procesador cuántico está en CrashLoopBackOff, instalamos dependencias
echo -e "\n7. Verificando el estado del procesador cuántico..."
QUANTUM_STATUS=$(kubectl get pods -n quantum-access-control -l app=raspberry-pi-gateway -o jsonpath='{.items[0].status.phase}')
if [ "$QUANTUM_STATUS" == "Running" ]; then
    echo "El procesador cuántico está funcionando correctamente"
else
    echo "Aplicando parche para instalar dependencias en el procesador cuántico..."
    kubectl patch deployment raspberry-pi-gateway -n quantum-access-control -p '{"spec":{"template":{"spec":{"containers":[{"name":"quantum-processor","command":["sh","-c","pip install numpy paho-mqtt requests && python -u /app/quantum_processor.py"]}]}}}}'
    sleep 5
    kubectl get pods -n quantum-access-control -l app=raspberry-pi-gateway
fi

# Desplegar monitor de rendimiento
echo -e "\n8. Desplegando monitor de rendimiento..."
kubectl apply -f k8s/monitoring/performance-monitor.yaml
sleep 5
kubectl get pods -n quantum-access-control -l app=performance-monitor

# Si el monitor está en CrashLoopBackOff, instalamos dependencias
echo -e "\n9. Verificando el estado del monitor de rendimiento..."
MONITOR_STATUS=$(kubectl get pods -n quantum-access-control -l app=performance-monitor -o jsonpath='{.items[0].status.phase}')
if [ "$MONITOR_STATUS" == "Running" ]; then
    echo "El monitor de rendimiento está funcionando correctamente"
else
    echo "Aplicando parche para instalar dependencias en el monitor de rendimiento..."
    kubectl patch deployment performance-monitor -n quantum-access-control -p '{"spec":{"template":{"spec":{"containers":[{"name":"performance-monitor","command":["sh","-c","pip install prometheus_client && python -u /app/performance_monitor.py"]}]}}}}'
    sleep 5
    kubectl get pods -n quantum-access-control -l app=performance-monitor
fi

# Mostrar estado final
echo -e "\n=== Estado final del despliegue ==="
kubectl get pods -n quantum-access-control

echo -e "\n=== Instrucciones para verificar el sistema ==="
echo "1. Para ver los logs del procesador cuántico:"
echo "   kubectl logs -n quantum-access-control -l app=raspberry-pi-gateway -c quantum-processor -f"
echo ""
echo "2. Para verificar que el broker MQTT funciona:"
echo "   kubectl logs -n quantum-access-control -l app=mqtt-broker -f"
echo ""
echo "3. Para verificar que Orion Context Broker está operativo:"
echo "   kubectl exec -it \$(kubectl get pods -n quantum-access-control -l app=orion -o jsonpath='{.items[0].metadata.name}') -n quantum-access-control -- curl localhost:1026/version"
