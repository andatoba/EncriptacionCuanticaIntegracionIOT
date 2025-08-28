#!/bin/bash

# Script para solucionar el problema de incompatibilidad de arquitectura de Orion en Raspberry Pi
echo "=== Solucionando problema de incompatibilidad de arquitectura de Orion Context Broker ==="

# 1. Identificar la arquitectura del sistema
echo "Arquitectura del sistema:"
uname -m

# 2. Eliminar el deployment actual de Orion
echo -e "\n1. Eliminando deployment actual de Orion Context Broker..."
kubectl delete deployment orion-context-broker -n quantum-access-control
sleep 5

# 3. Crear un nuevo deployment con una imagen compatible con ARM
echo -e "\n2. Creando nuevo deployment con imagen compatible con ARM..."

# Crear archivo de configuración con imagen compatible con ARM
cat > orion-arm.yaml << EOF
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
        image: telefonicaiot/fiware-orion:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 1026
        resources:
          limits:
            memory: "128Mi"
            cpu: "100m"
          requests:
            memory: "64Mi"
            cpu: "50m"
        env:
        - name: ORION_MONGO_HOST
          value: "mongodb"
        - name: ORION_LOG_LEVEL
          value: "INFO"
EOF

# Aplicar la nueva configuración
kubectl apply -f orion-arm.yaml

# 4. Esperar a que se cree el nuevo pod
echo -e "\n3. Esperando a que se cree el nuevo pod (30 segundos)..."
sleep 30

# 5. Verificar estado del nuevo pod
echo -e "\n4. Verificando estado del nuevo pod:"
kubectl get pods -n quantum-access-control -l app=orion-context-broker

# 6. Mostrar logs del nuevo pod
echo -e "\n5. Logs del nuevo pod (si está disponible):"
NEW_POD=$(kubectl get pods -n quantum-access-control -l app=orion-context-broker -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$NEW_POD" ]; then
    kubectl logs -n quantum-access-control $NEW_POD --tail=20
else
    echo "No se encontró ningún pod de Orion Context Broker"
fi

# 7. Si la imagen telefonicaiot/fiware-orion no funciona, probar con alternativas
echo -e "\n=== Si el problema persiste, prueba estas alternativas: ==="
echo "1. Usar imagen multiarch de fiware/orion-ld:"
echo "   kubectl set image deployment/orion-context-broker -n quantum-access-control orion=fiware/orion-ld:1.0.1"
echo ""
echo "2. Crear una imagen propia de Orion para ARM64:"
echo "   Sigue las instrucciones en: https://github.com/telefonicaid/fiware-orion/tree/master/docker"
echo ""
echo "3. Alternativa: Usar un despliegue más ligero sin Orion temporalmente"
echo "   kubectl delete deployment orion-context-broker -n quantum-access-control"
