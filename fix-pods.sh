#!/bin/bash

# Script para solucionar problemas comunes en el despliegue

echo "=== Solucionando problemas del despliegue ==="

# Verificar estado actual
echo "Estado actual de los pods:"
kubectl get pods -n quantum-access-control

# 1. Solucionar problema del Orion Context Broker (CrashLoopBackOff)
echo -e "\n1. Solucionando problema de Orion Context Broker..."
# Reduce los recursos y cambia a una imagen más ligera
kubectl patch deployment orion-context-broker -n quantum-access-control -p '{"spec":{"template":{"spec":{"containers":[{"name":"orion","image":"fiware/orion:2.4.0","resources":{"limits":{"memory":"256Mi","cpu":"200m"},"requests":{"memory":"128Mi","cpu":"100m"}}}]}}}}'
echo "Esperando a que Orion se reinicie..."
sleep 10
kubectl get pods -n quantum-access-control -l app=orion

# 2. Solucionar problema del Performance Monitor
echo -e "\n2. Solucionando problema del Performance Monitor..."
# Eliminar pods antiguos
kubectl delete pod -n quantum-access-control -l app=performance-monitor
# Modificar deployment para instalar dependencias
kubectl patch deployment performance-monitor -n quantum-access-control -p '{"spec":{"template":{"spec":{"containers":[{"name":"performance-monitor","command":["sh","-c","pip install prometheus_client && python -u /app/performance_monitor.py"]}]}}}}'
echo "Esperando a que Performance Monitor se reinicie..."
sleep 10
kubectl get pods -n quantum-access-control -l app=performance-monitor

# 3. Solucionar problema del Raspberry Pi Gateway
echo -e "\n3. Solucionando problema del Raspberry Pi Gateway..."
# Eliminar pods antiguos
kubectl delete pod -n quantum-access-control -l app=raspberry-pi-gateway
# Modificar deployment para instalar dependencias
kubectl patch deployment raspberry-pi-gateway -n quantum-access-control -p '{"spec":{"template":{"spec":{"containers":[{"name":"quantum-processor","command":["sh","-c","pip install numpy paho-mqtt requests && python -u /app/quantum_processor.py"]}]}}}}'
echo "Esperando a que Raspberry Pi Gateway se reinicie..."
sleep 10
kubectl get pods -n quantum-access-control -l app=raspberry-pi-gateway

# 4. Verificar logs de pods con problemas
echo -e "\n4. Verificando logs de pods con problemas..."
ORION_POD=$(kubectl get pods -n quantum-access-control -l app=orion -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$ORION_POD" ]; then
    echo "Logs de Orion Context Broker:"
    kubectl logs -n quantum-access-control $ORION_POD --tail=20
fi

MONITOR_POD=$(kubectl get pods -n quantum-access-control -l app=performance-monitor -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$MONITOR_POD" ]; then
    echo -e "\nLogs de Performance Monitor:"
    kubectl logs -n quantum-access-control $MONITOR_POD --tail=20
fi

GATEWAY_POD=$(kubectl get pods -n quantum-access-control -l app=raspberry-pi-gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$GATEWAY_POD" ]; then
    echo -e "\nLogs de Raspberry Pi Gateway (quantum-processor):"
    kubectl logs -n quantum-access-control $GATEWAY_POD -c quantum-processor --tail=20
fi

# 5. Estado final
echo -e "\n=== Estado final del despliegue ==="
kubectl get pods -n quantum-access-control

# 6. Instrucciones adicionales
echo -e "\n=== Soluciones adicionales ==="
echo "1. Si Orion sigue fallando, prueba con una imagen más ligera:"
echo "   kubectl set image deployment/orion-context-broker -n quantum-access-control orion=fiware/orion:2.0.0"
echo ""
echo "2. Si hay pods en estado ContainerCreating por mucho tiempo, verifica los recursos del nodo:"
echo "   kubectl describe node raspberrypi | grep -A 5 Allocatable"
echo ""
echo "3. Si la Raspberry Pi tiene recursos muy limitados, considera desactivar componentes no esenciales:"
echo "   kubectl scale deployment apache-nifi -n quantum-access-control --replicas=0"
echo "   kubectl scale deployment draco -n quantum-access-control --replicas=0"
