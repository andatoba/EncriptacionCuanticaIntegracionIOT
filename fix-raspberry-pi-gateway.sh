#!/bin/bash

# Script para solucionar el gateway Raspberry Pi
echo "=== Solucionando Raspberry Pi Gateway ==="

# 1. Eliminar el deployment actual
echo "1. Eliminando deployment actual de Raspberry Pi Gateway..."
kubectl delete deployment raspberry-pi-gateway -n quantum-access-control
sleep 5

# 2. Crear ConfigMap para el código si no existe
echo "2. Creando ConfigMap para el código del procesador cuántico..."
cat > quantum-processor-code.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: quantum-processor-code
  namespace: quantum-access-control
data:
  quantum_processor.py: |
    #!/usr/bin/env python3
    import time
    import random
    import json
    import os
    
    try:
      import paho.mqtt.client as mqtt
      import numpy as np
      import requests
    except ImportError:
      print("Dependencias no instaladas, intentando instalarlas...")
      os.system("pip install paho-mqtt numpy requests")
      import paho.mqtt.client as mqtt
      import numpy as np
      import requests
    
    # Simulación del protocolo BB84
    def bb84_simulation():
      # Bits aleatorios que Alice quiere transmitir
      alice_bits = [random.randint(0, 1) for _ in range(8)]
      
      # Bases aleatorias para Alice (0: rectilínea, 1: diagonal)
      alice_bases = [random.randint(0, 1) for _ in range(8)]
      
      # Alice prepara los qubits según sus bits y bases
      alice_qubits = []
      for i in range(8):
        if alice_bases[i] == 0:  # Base rectilínea
          alice_qubits.append(alice_bits[i])
        else:  # Base diagonal
          alice_qubits.append(alice_bits[i] + 2)
      
      # Bob elige bases aleatorias para medir
      bob_bases = [random.randint(0, 1) for _ in range(8)]
      
      # Bob mide los qubits
      bob_results = []
      for i in range(8):
        if bob_bases[i] == alice_bases[i]:  # Misma base, resultado correcto
          bob_results.append(alice_bits[i])
        else:  # Distinta base, resultado aleatorio
          bob_results.append(random.randint(0, 1))
      
      # Alice y Bob comparan bases (públicamente)
      shared_key = ""
      for i in range(8):
        if alice_bases[i] == bob_bases[i]:
          shared_key += str(alice_bits[i])
      
      return shared_key
    
    # UIDs autorizados (en una implementación real, se almacenarían de manera segura)
    authorized_uids = ["0A1B2C3D", "4E5F6G7H", "8I9J0K1L"]
    
    # Callback para cuando se recibe un mensaje MQTT
    def on_message(client, userdata, message):
      try:
        data = json.loads(message.payload.decode())
        print(f"Mensaje recibido: {data}")
        
        # Verificar si es una solicitud de acceso por RFID
        if "uid" in data:
          uid = data["uid"]
          
          # Generar clave cuántica compartida
          shared_key = bb84_simulation()
          print(f"Clave cuántica generada: {shared_key}")
          
          # Verificar autorización
          if uid in authorized_uids:
            access = "granted"
            print(f"Acceso permitido para UID: {uid}")
          else:
            access = "denied"
            print(f"Acceso denegado para UID: {uid}")
          
          # Enviar respuesta
          response = {
            "uid": uid,
            "access": access,
            "key": shared_key
          }
          
          client.publish("quantum/access/response", json.dumps(response))
          
          # Registrar evento en Orion Context Broker
          try:
            orion_data = {
              "id": f"AccessEvent_{time.time()}",
              "type": "AccessControl",
              "uid": {"type": "Text", "value": uid},
              "access": {"type": "Text", "value": access},
              "timestamp": {"type": "DateTime", "value": time.strftime("%Y-%m-%dT%H:%M:%SZ")}
            }
            
            r = requests.post(
              "http://orion-context-broker:1026/v2/entities",
              headers={"Content-Type": "application/json"},
              data=json.dumps(orion_data)
            )
            print(f"Evento registrado en Orion: {r.status_code}")
          except Exception as e:
            print(f"Error al registrar evento en Orion: {e}")
      
      except Exception as e:
        print(f"Error al procesar mensaje: {e}")
    
    # Configuración del cliente MQTT
    client = mqtt.Client("quantum_processor")
    
    # Conectar al broker MQTT
    try:
      client.connect("mqtt-broker", 1883, 60)
      print("Conectado al broker MQTT")
    except:
      print("No se pudo conectar al broker MQTT, usando modo simulación")
    
    # Suscribirse al tema de solicitudes de acceso
    client.subscribe("quantum/access/request")
    client.on_message = on_message
    
    print("Procesador cuántico iniciado, esperando solicitudes de acceso...")
    
    # Bucle para mantener la conexión MQTT
    try:
      client.loop_start()
      while True:
        # Simular solicitud de acceso cada 30 segundos en modo demo
        time.sleep(30)
        demo_uid = random.choice(authorized_uids + ["UNAUTHORIZED"])
        print(f"[DEMO] Simulando solicitud de acceso para UID: {demo_uid}")
        demo_data = {
          "uid": demo_uid
        }
        client.publish("quantum/access/request", json.dumps(demo_data))
    except KeyboardInterrupt:
      print("Procesador cuántico detenido")
      client.loop_stop()
EOF

# Aplicar ConfigMap
kubectl apply -f quantum-processor-code.yaml

# 3. Crear deployment compatible con ARM
echo "3. Creando deployment compatible con ARM para Raspberry Pi Gateway..."
cat > raspberry-pi-gateway-arm.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: raspberry-pi-gateway
  namespace: quantum-access-control
spec:
  replicas: 1
  selector:
    matchLabels:
      app: raspberry-pi-gateway
  template:
    metadata:
      labels:
        app: raspberry-pi-gateway
    spec:
      containers:
      - name: quantum-processor
        image: arm64v8/python:3.9-alpine
        imagePullPolicy: IfNotPresent
        command: ["sh", "-c"]
        args: ["apk add --no-cache gcc musl-dev && pip install numpy paho-mqtt requests && python -u /app/quantum_processor.py || sleep 3600"]
        resources:
          limits:
            memory: "128Mi"
            cpu: "100m"
          requests:
            memory: "64Mi"
            cpu: "50m"
        volumeMounts:
        - name: code-volume
          mountPath: /app
      - name: mqtt-relay
        image: arm64v8/eclipse-mosquitto:1.6
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            memory: "64Mi"
            cpu: "50m"
          requests:
            memory: "32Mi"
            cpu: "25m"
      volumes:
      - name: code-volume
        configMap:
          name: quantum-processor-code
EOF

# Aplicar deployment
kubectl apply -f raspberry-pi-gateway-arm.yaml

# 4. Verificar estado
echo "4. Verificando estado del pod..."
sleep 10
kubectl get pods -n quantum-access-control -l app=raspberry-pi-gateway

echo "=== Implementación de Raspberry Pi Gateway completada ==="
echo "Para ver logs: kubectl logs -n quantum-access-control -l app=raspberry-pi-gateway -c quantum-processor"
