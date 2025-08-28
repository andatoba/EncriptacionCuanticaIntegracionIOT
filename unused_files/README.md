# Directorio de Archivos No Utilizados

Este directorio contiene archivos que ya no son necesarios para el funcionamiento principal del sistema de control de acceso cuántico, pero que se han conservado por referencia histórica o en caso de que se necesiten en el futuro.

## Categorías de Archivos

### 1. Scripts de Despliegue Redundantes

- `deploy.sh` - Script de despliegue original, reemplazado por versiones más optimizadas para ARM
- `deploy-light.sh` - Versión ligera del script de despliegue, reemplazada por deploy-light-arm.sh
- `deploy-fixed.sh` - Script con correcciones específicas, funcionalidad incorporada en otros scripts
- `deploy-progresivo.sh` - Script para despliegue progresivo paso a paso

### 2. Scripts de Solución Antiguos

- `fix-orion.sh` - Solución inicial para Orion Context Broker
- `fix-orion-v2.sh` - Segunda versión de la solución para Orion
- `fix-orion-arm.sh` - Primera versión de la solución específica para ARM

### 3. Archivos Temporales

- `new.txt` - Archivo temporal de notas o pruebas

### 4. Manifiestos de Componentes No Utilizados

- `k8s/cloud-processing/nifi-deployment.yaml` - Apache NiFi no es compatible con ARM64 o no se está utilizando
- `k8s/cloud-processing/nifi-service.yaml` - Servicio para Apache NiFi
- `k8s/cloud-processing/draco-deployment.yaml` - Fiware Draco no es compatible o no se está utilizando
- `k8s/cloud-processing/draco-service.yaml` - Servicio para Fiware Draco
- `k8s/cloud-processing/create-subscriptions-job.yaml` - Trabajo para crear suscripciones, no necesario en la implementación actual

### 5. Archivos Experimentales

- `comunicacionalicebobcs.py` - Implementación experimental de la encriptación cuántica BB84

## Nota Importante

Si se necesita restaurar alguna funcionalidad o revisar implementaciones anteriores, estos archivos pueden ser consultados o movidos de nuevo al directorio principal del proyecto. Se recomienda revisar cuidadosamente su contenido antes de utilizarlos nuevamente.

Fecha de reorganización: 28 de agosto de 2025
