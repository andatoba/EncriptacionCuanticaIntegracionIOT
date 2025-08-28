#!/bin/bash

# Script mejorado para solucionar definitivamente el problema de Orion Context Broker
echo "=== Solución definitiva para Orion Context Broker en Raspberry Pi ==="

# Crear archivo de configuración optimizado para Raspberry Pi
cat > orion-optimized.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orion-context-broker
  namespace: quantum-access-control
spec:
  replicas: 1
  selector:
    matchLabels:
      app: orion-context-broker
  template:
    metadata:
      labels:
        app: orion-context-broker
    spec:
      containers:
      - name: orion
        image: fiware/orion:2.0.0
        imagePullPolicy: IfNotPresent
        command: ["/usr/bin/contextBroker"]
        args: ["-dbhost", "mongodb", "-logLevel", "INFO", "-logForHumans"]
        ports:
        - containerPort: 1026
        resources:
          limits:
            memory: "128Mi"
            cpu: "100m"
          requests:
            memory: "64Mi"
            cpu: "50m"
EOF

# Eliminar el deployment actual para aplicar uno nuevo desde cero
echo "1. Eliminando deployment actual de Orion Context Broker..."
kubectl delete deployment orion-context-broker -n quantum-access-control

# Esperar a que se elimine completamente
echo "2. Esperando a que se elimine el deployment (5 segundos)..."
sleep 5

# Aplicar la nueva configuración optimizada
echo "3. Aplicando configuración optimizada para Raspberry Pi..."
kubectl apply -f orion-optimized.yaml

# Esperar a que se cree el nuevo pod
echo "4. Esperando a que se cree el nuevo pod (30 segundos)..."
sleep 30

# Verificar el estado del servicio de MongoDB (Orion lo necesita)
echo "5. Verificando que el servicio de MongoDB está disponible..."
kubectl get service mongodb -n quantum-access-control
kubectl get pods -n quantum-access-control -l app=mongodb

# Verificar estado del nuevo pod de Orion
echo "6. Verificando estado del nuevo pod de Orion:"
kubectl get pods -n quantum-access-control -l app=orion-context-broker

# Mostrar logs del nuevo pod para diagnóstico
echo "7. Mostrando logs del nuevo pod para diagnóstico:"
NEW_POD=$(kubectl get pods -n quantum-access-control -l app=orion-context-broker -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$NEW_POD" ]; then
    kubectl logs -n quantum-access-control $NEW_POD --tail=20
else
    echo "No se encontró ningún pod de Orion Context Broker"
fi

# Comprobar si el servicio de Orion está definido correctamente
echo "8. Verificando definición del servicio Orion Context Broker:"
kubectl get service orion-context-broker -n quantum-access-control || echo "El servicio no existe, creándolo..."
if [ $? -ne 0 ]; then
    # Crear el servicio si no existe
    cat > orion-service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: orion-context-broker
  namespace: quantum-access-control
spec:
  ports:
  - port: 1026
    targetPort: 1026
    protocol: TCP
  selector:
    app: orion-context-broker
EOF
    kubectl apply -f orion-service.yaml
fi

echo -e "\n=== Estado final del sistema ==="
kubectl get pods -n quantum-access-control
