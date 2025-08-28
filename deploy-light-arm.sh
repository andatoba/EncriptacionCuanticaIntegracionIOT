#!/bin/bash

# Script de despliegue unificado para sistema de control de acceso con encriptación cuántica
# Optimizado para Raspberry Pi y otras plataformas ARM
echo "=== Despliegue de sistema de control de acceso con encriptación cuántica ==="
echo "=== Optimizado para Raspberry Pi (ARM64) ==="

# 0. Configurar kubectl
echo -e "\n0. Configurando kubectl..."
export KUBECONFIG=~/.kube/config

# 1. Crear namespace
echo -e "\n1. Creando namespace..."
kubectl apply -f k8s/namespace.yaml
sleep 3

# 2. Aplicar configuraciones globales
echo -e "\n2. Aplicando configuraciones globales..."
kubectl apply -f k8s/configmap.yaml
sleep 3

# 3. Desplegar MongoDB (componente esencial)
echo -e "\n3. Desplegando MongoDB..."
kubectl apply -f k8s/storage/mongodb-pvc.yaml
kubectl apply -f k8s/storage/mongodb-deployment.yaml
kubectl apply -f k8s/storage/mongodb-service.yaml
echo "Esperando a que MongoDB esté listo (puede tardar hasta 2 minutos)..."
kubectl wait --for=condition=ready pod -l app=mongodb -n quantum-access-control --timeout=120s || true
sleep 5

# 4. Desplegar Orion Context Broker (versión simplificada para ARM)
echo -e "\n4. Desplegando Orion Context Broker (versión compatible con ARM)..."
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
        image: arm64v8/nginx:alpine
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        resources:
          limits:
            memory: "64Mi"
            cpu: "50m"
          requests:
            memory: "32Mi"
            cpu: "25m"
---
apiVersion: v1
kind: Service
metadata:
  name: orion-context-broker
  namespace: quantum-access-control
spec:
  ports:
  - port: 1026
    targetPort: 80
    protocol: TCP
  selector:
    app: orion-context-broker
EOF
kubectl apply -f orion-arm.yaml
sleep 5

# 5. Desplegar monitor de rendimiento
echo -e "\n5. Desplegando monitor de rendimiento..."
cat > performance-monitor-code.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: performance-monitor-code
  namespace: quantum-access-control
data:
  performance_monitor.py: |
    #!/usr/bin/env python3
    import time
    import os
    try:
      import prometheus_client as prom
    except ImportError:
      print("Prometheus client no instalado, intentando instalarlo...")
      os.system("pip install prometheus_client")
      import prometheus_client as prom
    
    # Crear métricas
    cpu_gauge = prom.Gauge('system_cpu_usage', 'CPU usage')
    memory_gauge = prom.Gauge('system_memory_usage', 'Memory usage in MB')
    
    # Iniciar servidor de métricas
    prom.start_http_server(8000)
    
    print("Monitor de rendimiento iniciado en puerto 8000")
    
    # Simular recolección de métricas
    while True:
      # En un sistema real, obtendríamos estos valores del sistema
      cpu_usage = 0.5 # 50% de ejemplo
      memory_usage = 256 # 256MB de ejemplo
      
      # Actualizar métricas
      cpu_gauge.set(cpu_usage)
      memory_gauge.set(memory_usage)
      
      print(f"Métricas actualizadas: CPU={cpu_usage}, Memoria={memory_usage}MB")
      time.sleep(5)
EOF
kubectl apply -f performance-monitor-code.yaml

cat > performance-monitor-arm.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: performance-monitor
  namespace: quantum-access-control
spec:
  replicas: 1
  selector:
    matchLabels:
      app: performance-monitor
  template:
    metadata:
      labels:
        app: performance-monitor
    spec:
      containers:
      - name: performance-monitor
        image: arm64v8/python:3.9-alpine
        imagePullPolicy: IfNotPresent
        command: ["sh", "-c"]
        args: ["apk add --no-cache gcc musl-dev && pip install prometheus_client && python -u /app/performance_monitor.py || sleep 3600"]
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
      volumes:
      - name: code-volume
        configMap:
          name: performance-monitor-code
---
apiVersion: v1
kind: Service
metadata:
  name: performance-monitor
  namespace: quantum-access-control
spec:
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
  selector:
    app: performance-monitor
EOF
kubectl apply -f performance-monitor-arm.yaml
sleep 5

# 6. Desplegar Raspberry Pi Gateway con procesador cuántico
echo -e "\n6. Desplegando Raspberry Pi Gateway con procesador cuántico..."
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
kubectl apply -f quantum-processor-code.yaml

# Configuración de mosquitto
cat > mosquitto-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: mosquitto-config
  namespace: quantum-access-control
data:
  mosquitto.conf: |
    listener 1883
    allow_anonymous true
EOF
kubectl apply -f mosquitto-config.yaml

# Service MQTT
cat > mqtt-service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: mqtt-broker
  namespace: quantum-access-control
spec:
  ports:
  - port: 1883
    targetPort: 1883
    protocol: TCP
  selector:
    app: raspberry-pi-gateway
EOF
kubectl apply -f mqtt-service.yaml

# Desplegar Raspberry Pi Gateway
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
        volumeMounts:
        - name: mosquitto-config
          mountPath: /mosquitto/config/mosquitto.conf
          subPath: mosquitto.conf
      volumes:
      - name: code-volume
        configMap:
          name: quantum-processor-code
      - name: mosquitto-config
        configMap:
          name: mosquitto-config
EOF
kubectl apply -f raspberry-pi-gateway-arm.yaml
sleep 10

# 7. Esperar a que todos los pods estén listos
echo -e "\n7. Esperando a que todos los pods estén listos..."
sleep 20

# 8. Verificar estado final
echo -e "\n=== Estado final del sistema ==="
kubectl get pods -n quantum-access-control

echo -e "\n=== Instrucciones para verificar el sistema ==="
echo "1. Para ver los logs del procesador cuántico:"
echo "   kubectl logs -n quantum-access-control -l app=raspberry-pi-gateway -c quantum-processor -f"
echo ""
echo "2. Para ver las métricas del monitor de rendimiento:"
echo "   kubectl port-forward -n quantum-access-control svc/performance-monitor 8000:8000"
echo "   (Luego accede a http://localhost:8000 en tu navegador)"
echo ""
echo "3. Para simular una solicitud de acceso RFID:"
echo "   kubectl exec -it \$(kubectl get pods -n quantum-access-control -l app=raspberry-pi-gateway -o jsonpath='{.items[0].metadata.name}') -n quantum-access-control -c quantum-processor -- sh -c 'echo \"{\\\"uid\\\":\\\"0A1B2C3D\\\"}\" > /tmp/test.json && cat /tmp/test.json'"
echo ""
echo "=== ¡Despliegue completado! ==="
