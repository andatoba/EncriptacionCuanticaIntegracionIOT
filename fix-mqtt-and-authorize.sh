#!/bin/bash

# Script para modificar el procesador cuántico para que escuche en el tema MQTT correcto
# y añadir un UUID autorizado

echo "Modificando el procesador cuántico para escuchar en el tema MQTT correcto..."
echo "Añadiendo UUID e4e0ef2a a la lista de autorizados..."

# Ejecutar dentro del pod del procesador cuántico
sudo kubectl exec -it $(kubectl get pods -n quantum-access-control -l app=raspberry-pi-gateway -o jsonpath='{.items[0].metadata.name}') -n quantum-access-control -c quantum-processor -- python3 -c "
import os

# Leer el archivo del procesador cuántico
with open('/app/quantum_processor.py', 'r') as f:
    code = f.read()

# Cambiar el tema MQTT
code = code.replace('quantum/access/request', 'qsensor/rfid')

# Buscar la línea donde se definen los UIDs autorizados
lines = code.split('\\n')
for i, line in enumerate(lines):
    if 'authorized_uids = [' in line:
        # Verificar si el UUID ya está en la lista
        if 'e4e0ef2a' not in line:
            # Agregar el nuevo UUID (convertido a mayúsculas)
            lines[i] = line.replace(']', ', \\\"E4E0EF2A\\\"]')
            print('UUID E4E0EF2A agregado a la lista de autorizados')
        else:
            print('UUID E4E0EF2A ya está en la lista de autorizados')
        break

# Guardar el archivo modificado
with open('/tmp/quantum_processor_updated.py', 'w') as f:
    f.write('\\n'.join(lines))

# Actualizar el código en la aplicación
os.system('cp /tmp/quantum_processor_updated.py /app/quantum_processor.py')
print('Archivo actualizado exitosamente')
"

echo "Reiniciando el pod del procesador cuántico para aplicar los cambios..."
sudo kubectl delete pod $(kubectl get pods -n quantum-access-control -l app=raspberry-pi-gateway -o jsonpath='{.items[0].metadata.name}') -n quantum-access-control

echo "Esperando a que el pod se reinicie..."
sleep 10

echo "Verificando el estado del pod..."
sudo kubectl get pods -n quantum-access-control -l app=raspberry-pi-gateway

echo "¡Listo! El procesador cuántico ahora está escuchando en el tema MQTT correcto"
echo "y tu UUID e4e0ef2a ha sido añadido a la lista de autorizados."
