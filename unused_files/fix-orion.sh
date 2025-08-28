#!/bin/bash

# Script para solucionar el problema de Orion Context Broker
echo "=== Solucionando el problema de Orion Context Broker ==="

# 1. Verificar el estado actual
echo "Estado actual de Orion Context Broker:"
kubectl get pods -n quantum-access-control -l app=orion-context-broker

# 2. Aplicar parche para usar una imagen más antigua y confiable con el comando correcto
echo "Aplicando solución..."
kubectl patch deployment orion-context-broker -n quantum-access-control -p '{"spec":{"template":{"spec":{"containers":[{"name":"orion","image":"fiware/orion:2.4.0","command":["/usr/bin/contextBroker","-dbhost","mongodb","-logLevel","INFO","-dbTimeout","10000","-maxConnections","10"]}]}}}}'

# 3. Esperar a que se aplique el cambio
echo "Esperando a que se aplique el cambio..."
sleep 10

# 4. Verificar el nuevo estado
echo "Nuevo estado de Orion Context Broker:"
kubectl get pods -n quantum-access-control -l app=orion-context-broker

# 5. Verificar logs del nuevo pod
echo "Logs del nuevo pod (si está disponible):"
NEW_POD=$(kubectl get pods -n quantum-access-control -l app=orion-context-broker -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$NEW_POD" ]; then
    kubectl logs -n quantum-access-control $NEW_POD --tail=20
else
    echo "No se pudo obtener el nombre del pod de Orion Context Broker."
fi

echo -e "\n=== Si el problema persiste ==="
echo "1. Prueba con una imagen aún más antigua:"
echo "   kubectl patch deployment orion-context-broker -n quantum-access-control -p '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"orion\",\"image\":\"fiware/orion:2.0.0\",\"command\":[\"/usr/bin/contextBroker\",\"-dbhost\",\"mongodb\",\"-logLevel\",\"INFO\"]}]}}}}'"
echo ""
echo "2. Verifica que MongoDB esté funcionando correctamente:"
echo "   kubectl get pods -n quantum-access-control -l app=mongodb"
