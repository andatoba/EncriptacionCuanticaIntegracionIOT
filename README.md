# Sistema de Control de Acceso con Encriptación Cuántica para Edificio en Guayaquil

Este proyecto implementa un sistema completo de control de acceso utilizando simulación de encriptación cuántica (protocolo BB84) con una arquitectura multi-capa optimizada para dispositivos ARM (Raspberry Pi):

1. **Capa IoT Edge**: ESP32 + RFID con simulación de protocolo BB84
2. **Capa Edge Processing**: Raspberry Pi como gateway y procesador cuántico
3. **Capa Cloud Processing**: Data Processor y Orion Context Broker simplificado
4. **Capa de Monitoreo**: Prometheus y Grafana
5. **Capa de Visualización**: Dashboard Frontend para administración de accesos

## Arquitectura del Sistema

```
+---------------+        +---------------+        +---------------+        +---------------+
|               |        |               |        |               |        |               |
| ESP32 + RFID  +------->+ Raspberry Pi  +------->+   Dashboard   +------->+  Prometheus  |
| (Edge Device) |        | Gateway + MQTT|        |   Frontend    |        |  Monitoring  |
|    MQTT       |        |               |        |               |        |               |
+---------------+        +------+--------+        +-------+-------+        +-------+-------+
                                |                         |                        |
                                v                         v                        v
                        +---------------+         +---------------+        +---------------+
                        |               |         |               |        |               |
                        | Data Processor+-------->+    Orion     |        |    Grafana    |
                        |               |         |Context Broker|        |  Dashboard    |
                        |               |         | (Simplificado)|       |               |
                        +---------------+         +-------+-------+        +---------------+
                                                          |
                                                          v
                                                  +---------------+
                                                  |               |
                                                  |   MongoDB     |
                                                  |  (Database)   |
                                                  |               |
                                                  +---------------+
```

## Implementación

### Requisitos

- Kubernetes cluster (Minikube, K3s, etc.)
- kubectl configurado
- Docker
- Un sistema Linux o Windows con WSL para ejecutar los scripts

### Estructura de Carpetas

```
proyecto/
├── add_authorized_rfid.sh       # Script para agregar tarjetas RFID autorizadas
├── deploy-light-arm.sh          # Script de despliegue optimizado para ARM
├── fix-mqtt-and-authorize.sh    # Script para corregir configuración MQTT
├── fix-orion-arm-v2.sh          # Script para solucionar Orion en ARM
├── fix-performance-monitor.sh   # Script para solucionar monitor de rendimiento
├── fix-raspberry-pi-gateway.sh  # Script para solucionar gateway de Raspberry Pi
├── orion-service.yaml           # Servicio para Orion Context Broker
├── orion-simplified.yaml        # Implementación simplificada de Orion para ARM
├── troubleshoot.sh              # Script para diagnóstico y solución de problemas
├── continue-deploy.sh           # Script para continuar despliegue
├── edge-device/
│   └── esp32_rfid_bb84.ino      # Código para ESP32 + RFID con BB84
├── k8s/                         # Manifiestos de Kubernetes
│   ├── configmap.yaml
│   ├── namespace.yaml
│   ├── ingress.yaml
│   ├── dashboard-frontend-deployment.yaml  # Frontend para visualización
│   ├── dashboard-frontend-service.yaml     # Servicio para el frontend
│   ├── mqtt-nodeport-service.yaml          # Servicio para MQTT
│   ├── edge-device/             # Manifiestos para el dispositivo IoT
│   │   ├── esp32-configmap.yaml
│   │   ├── esp32-deployment.yaml
│   │   └── esp32-simulator-code.yaml
│   ├── edge-server/             # Manifiestos para el servidor de borde
│   │   ├── mosquitto-config.yaml
│   │   ├── mqtt-service.yaml
│   │   ├── quantum-processor-code.yaml
│   │   └── raspberry-pi-deployment.yaml
│   ├── cloud-processing/        # Manifiestos para procesamiento en la nube
│   │   ├── data-processor-code.yaml
│   │   ├── data-processor-deployment.yaml
│   │   ├── orion-deployment.yaml
│   │   ├── orion-service.yaml
│   │   └── subscription-config.yaml
│   ├── monitoring/              # Manifiestos para monitoreo
│   │   ├── performance_monitor.py
│   │   ├── performance-monitor-code.yaml
│   │   ├── performance-monitor.yaml
│   │   ├── grafana/             # Configuración de Grafana
│   │   └── prometheus/          # Configuración de Prometheus
│   └── storage/                 # Manifiestos para almacenamiento
│       ├── mongodb-deployment.yaml
│       ├── mongodb-pvc.yaml
│       └── mongodb-service.yaml
└── unused_files/                # Archivos obsoletos o no utilizados
```

### Despliegue

Para desplegar el sistema completo en Raspberry Pi (ARM64):

```bash
chmod +x deploy-light-arm.sh
./deploy-light-arm.sh
```

Para solucionar problemas específicos:

```bash
# Solucionar problemas con Orion Context Broker
./fix-orion-arm-v2.sh

# Solucionar problemas con el procesador cuántico
./fix-raspberry-pi-gateway.sh

# Solucionar problemas con el monitor de rendimiento
./fix-performance-monitor.sh
```

### Acceso a Servicios

Una vez desplegado, podrás acceder a los siguientes servicios a través de la IP del nodo:

- Dashboard: http://192.168.100.244:30080
- Orion Context Broker API: http://192.168.100.244:30080/orion-proxy/v2/entities
- Grafana: http://192.168.100.244:30080/grafana (admin/admin)
- Prometheus: http://192.168.100.244:30080/prometheus

### Administración de Tarjetas RFID

Para agregar una tarjeta RFID autorizada:

```bash
./add_authorized_rfid.sh <UUID> "<Nombre de Usuario>"
```

Para consultar las tarjetas autorizadas:

```bash
ssh id@192.168.100.244 "curl 'http://192.168.100.244:30080/orion-proxy/v2/entities?type=AuthorizedCard&options=keyValues' -s | jq"
```

Para ver los accesos recientes:

```bash
ssh id@192.168.100.244 "curl 'http://192.168.100.244:30080/orion-proxy/v2/entities?type=RFIDCard&options=keyValues&limit=5&orderBy=!timestamp' -s | jq"
```

## Flujo de Datos

1. **Detección de Tarjeta RFID**: El ESP32 lee una tarjeta RFID y simula un intercambio BB84
2. **Envío MQTT**: Los datos se envían por MQTT al tema `qsensor/rfid`
3. **Procesamiento Cuántico**: El procesador cuántico en la Raspberry Pi verifica la tarjeta y genera una clave compartida
4. **Data Processor**: El procesador de datos envía la información a Orion Context Broker
5. **Almacenamiento**: Los datos se almacenan en MongoDB para consultas históricas
6. **Visualización**: El Dashboard Frontend muestra el estado del sistema y los accesos recientes
7. **Monitoreo**: Prometheus recopila métricas y Grafana las visualiza

## Tecnologías Utilizadas

- **Protocolo BB84 (simulado)**: Implementación simplificada del protocolo de encriptación cuántica.
- **ESP32 + RFID**: Dispositivo IoT para control de acceso.
- **MQTT**: Protocolo de comunicación entre ESP32 y Raspberry Pi.
- **Raspberry Pi**: Gateway IoT que procesa datos y ejecuta algoritmos BB84.
- **Orion Context Broker (simplificado)**: Broker de contexto para gestión de entidades, implementación Python/Flask para ARM64.
- **MongoDB**: Base de datos para almacenamiento principal.
- **Prometheus y Grafana**: Para monitorización y visualización.
- **Nginx**: Dashboard frontend para visualización del sistema.
- **Kubernetes (K3s)**: Orquestación de contenedores para Raspberry Pi (ARM64).

## Verificación del Sistema

Para verificar el funcionamiento del sistema:

1. **Verificar los pods**:
   ```bash
   ssh id@192.168.100.244 "sudo kubectl get pods -n quantum-access-control"
   ```

2. **Verificar el broker MQTT**:
   ```bash
   ssh id@192.168.100.244 "sudo kubectl exec -n quantum-access-control raspberry-pi-gateway-XXXXX-XXXX -c mqtt-relay -- mosquitto_sub -v -t 'qsensor/#' -h localhost -p 1883 -C 5"
   ```

3. **Verificar el procesador cuántico**:
   ```bash
   ssh id@192.168.100.244 "sudo kubectl logs -n quantum-access-control raspberry-pi-gateway-XXXXX-XXXX -c quantum-processor --tail=20"
   ```

4. **Verificar Orion Context Broker**:
   ```bash
   ssh id@192.168.100.244 "curl -s -X GET http://orion-context-broker:1026/version -H 'Accept: application/json'"
   ```

## Solución de Problemas Comunes

1. **Pods en estado CrashLoopBackOff**:
   - Verifica los logs: `kubectl logs -n quantum-access-control <nombre-pod>`
   - Aplica el script de solución correspondiente

2. **Problemas con Orion Context Broker**:
   - Ejecuta: `./fix-orion-arm-v2.sh`
   - Asegúrate de que MongoDB está funcionando correctamente

3. **Problemas con el procesador cuántico**:
   - Ejecuta: `./fix-raspberry-pi-gateway.sh`
   - Verifica que la configuración MQTT es correcta

4. **Problemas con el monitor de rendimiento**:
   - Ejecuta: `./fix-performance-monitor.sh`

## Mantenimiento

El directorio `unused_files` contiene archivos que ya no son utilizados actualmente (como configuraciones de NiFi y Draco que no son compatibles con ARM64) pero se conservan como referencia. Consulta el README.md en ese directorio para más información.
