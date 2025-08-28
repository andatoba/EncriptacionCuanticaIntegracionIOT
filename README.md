# Sistema de Control de Acceso con Encriptación Cuántica

Este proyecto implementa un sistema completo de control de acceso utilizando encriptación cuántica (protocolo BB84) con una arquitectura multi-capa:

1. **Capa IoT Edge**: ESP32 + RFID con implementación simplificada de BB84
2. **Capa Edge Processing**: Raspberry Pi como gateway y procesador local
3. **Capa Cloud Processing**: NiFi, Orion Context Broker, Draco y bases de datos
4. **Capa de Monitoreo**: Prometheus y Grafana

## Arquitectura del Sistema

```
+---------------+        +---------------+        +---------------+        +---------------+
|               |        |               |        |               |        |               |
| ESP32 + RFID  +------->+ Raspberry Pi  +------->+    Ingress    +------->+  Prometheus  |
| (Edge Device) |        | (Edge Server) |        | (Kubernetes)  |        |  Monitoring  |
|               |        |               |        |               |        |               |
+---------------+        +---------------+        +-------+-------+        +-------+-------+
                                                         |                        |
                                                         v                        v
                           +---------------+        +---------------+        +---------------+
                           |               |        |               |        |               |
                           |  Apache NiFi  |<-------+    Orion     |        |    Grafana    |
                           | (Data Flow)   |        |Context Broker|        |  Dashboard    |
                           |               |        |               |        |               |
                           +-------+-------+        +-------+-------+        +---------------+
                                   |                        |
                                   v                        v
                           +---------------+        +---------------+        +---------------+
                           |               |        |               |        |               |
                           |     Draco     |------->+   MongoDB    |        | ElasticSearch |
                           | (Persistence) |        |  (Database)  |        |   (Storage)   |
                           |               |        |               |        |               |
                           +---------------+        +---------------+        +---------------+
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
├── comunicacionalicebobcs.py    # Algoritmo de encriptación cuántica (BB84)
├── deploy.sh                    # Script de despliegue
├── edge-device/
│   └── esp32_rfid_bb84.ino      # Código para ESP32 + RFID
└── k8s/                         # Manifiestos de Kubernetes
    ├── configmap.yaml
    ├── namespace.yaml
    ├── ingress.yaml
    ├── edge-device/             # Manifiestos para el dispositivo IoT
    ├── edge-server/             # Manifiestos para el servidor de borde
    ├── cloud-processing/        # Manifiestos para el procesamiento en la nube
    ├── monitoring/              # Manifiestos para monitoreo
    └── storage/                 # Manifiestos para almacenamiento
```

### Despliegue

Para desplegar el sistema completo:

```bash
chmod +x deploy.sh
./deploy.sh
```

### Acceso a Servicios

Una vez desplegado, agrega la siguiente entrada a tu archivo hosts:

```
127.0.0.1 quantum-access.local
```

Luego podrás acceder a los siguientes servicios:

- Orion Context Broker: http://quantum-access.local/orion
- Apache NiFi: http://quantum-access.local/nifi
- Draco: http://quantum-access.local/draco
- Grafana: http://quantum-access.local/grafana (admin/admin)
- Prometheus: http://quantum-access.local/prometheus

## Tecnologías Utilizadas

- **Protocolo BB84**: Implementación simplificada del protocolo de encriptación cuántica.
- **ESP32 + RFID**: Dispositivo IoT para control de acceso.
- **MQTT**: Protocolo de comunicación entre ESP32 y Raspberry Pi.
- **Raspberry Pi**: Gateway IoT que procesa datos y ejecuta algoritmos BB84.
- **Orion Context Broker**: Broker de contexto FIWARE para gestión de entidades.
- **Apache NiFi**: Para el flujo y procesamiento de datos.
- **Draco**: Conector FIWARE para persistencia de datos históricos.
- **MongoDB**: Base de datos para almacenamiento principal.
- **ElasticSearch**: Para almacenamiento y búsqueda de logs.
- **Prometheus y Grafana**: Para monitorización y visualización.
