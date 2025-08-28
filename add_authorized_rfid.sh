#!/bin/bash

# Script para agregar un nuevo UUID autorizado al sistema
# Uso: ./add_authorized_rfid.sh <UUID> <nombre_usuario>

# Verificar si se proporcionaron los argumentos necesarios
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Error: Debe proporcionar el UUID de la tarjeta RFID y el nombre del usuario"
  echo "Uso: ./add_authorized_rfid.sh <UUID> <nombre_usuario>"
  exit 1
fi

UUID=$1
USER_NAME=$2
CURRENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
VALID_UNTIL=$(date -u -d "+1 year" +"%Y-%m-%dT%H:%M:%SZ")

echo "Agregando UUID: $UUID a la lista de tarjetas autorizadas..."
echo "Usuario: $USER_NAME"
echo "Válida hasta: $VALID_UNTIL"

# Registrar la tarjeta en Orion Context Broker
echo "Registrando tarjeta en Orion Context Broker..."

# Obtener el nombre del pod del procesador cuántico
POD_NAME=$(kubectl get pods -n quantum-access-control -l app=raspberry-pi-gateway -o jsonpath='{.items[0].metadata.name}')

# Agregar el UUID a la lista de UIDs autorizados en el procesador cuántico
kubectl exec -it $POD_NAME -n quantum-access-control -c quantum-processor -- sh -c "python3 -c \"
import os
code_file = '/app/quantum_processor.py'
with open(code_file, 'r') as f:
    code = f.read()
# Encontrar la línea donde se definen los UIDs autorizados
lines = code.split('\\n')
for i, line in enumerate(lines):
    if 'authorized_uids = [' in line:
        # Agregar el nuevo UUID a la lista
        uuid = '$UUID'
        if uuid not in line:
            lines[i] = line.replace(']', ', \\\"$UUID\\\"]')
        break
# Guardar el código modificado
with open('/tmp/quantum_processor_updated.py', 'w') as f:
    f.write('\\n'.join(lines))
print('UUID $UUID agregado a la lista de autorizados')
\""

# Actualizar el ConfigMap

# Registrar la tarjeta en Orion Context Broker
kubectl exec -it $POD_NAME -n quantum-access-control -c quantum-processor -- curl -s -X POST \
  'http://orion-context-broker:1026/v2/entities' \
  -H 'Content-Type: application/json' \
  -d '{
  "id": "AuthorizedCard:'$UUID'",
  "type": "AuthorizedCard",
  "cardId": {"value": "'$UUID'", "type": "Text"},
  "userName": {"value": "'$USER_NAME'", "type": "Text"},
  "createdAt": {"value": "'$CURRENT_DATE'", "type": "DateTime"},
  "validUntil": {"value": "'$VALID_UNTIL'", "type": "DateTime"},
  "active": {"value": true, "type": "Boolean"}
}'

echo "Tarjeta registrada en Orion Context Broker"
echo "Actualizando ConfigMap con el nuevo UUID autorizado..."
# Primero guardamos el código actualizado en un archivo local
kubectl cp $POD_NAME:/tmp/quantum_processor_updated.py -n quantum-access-control quantum_processor_updated.py -c quantum-processor

# Luego actualizamos el ConfigMap con el nuevo archivo
kubectl create configmap quantum-processor-code --from-file=quantum_processor.py=quantum_processor_updated.py -n quantum-access-control --dry-run=client -o yaml | kubectl apply -f -

# Reiniciar el pod para aplicar los cambios
echo "Reiniciando el pod para aplicar los cambios..."
kubectl delete pod $POD_NAME -n quantum-access-control

echo "Esperando a que el pod se reinicie..."
sleep 10

# Verificar el estado del pod
kubectl get pods -n quantum-access-control -l app=raspberry-pi-gateway

echo "¡UUID $UUID agregado exitosamente a la lista de tarjetas autorizadas!"
echo "Prueba el acceso acercando la tarjeta RFID al lector."
