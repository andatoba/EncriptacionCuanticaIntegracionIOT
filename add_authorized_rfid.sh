#!/bin/bash

# Script para agregar un nuevo UUID autorizado al sistema
# Uso: ./add_authorized_rfid.sh <UUID>

# Verificar si se proporcionó un UUID
if [ -z "$1" ]; then
  echo "Error: Debe proporcionar el UUID de la tarjeta RFID"
  echo "Uso: ./add_authorized_rfid.sh <UUID>"
  exit 1
fi

UUID=$1
echo "Agregando UUID: $UUID a la lista de tarjetas autorizadas..."

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
