#!/usr/bin/env python3

"""
Monitor de rendimiento para el sistema de control de acceso con encriptación cuántica.
Este script recopila métricas del sistema y las exporta a Prometheus.
"""

import time
import random
import http.server
import json
from prometheus_client import start_http_server, Gauge, Counter, Histogram

# Métricas de Prometheus
ACCESS_ATTEMPTS = Counter('quantum_access_attempts_total', 'Total de intentos de acceso')
ACCESS_SUCCESS = Counter('quantum_access_success_total', 'Total de accesos exitosos')
ACCESS_DENIED = Counter('quantum_access_denied_total', 'Total de accesos denegados')
KEY_QUALITY = Gauge('quantum_key_quality', 'Calidad de la clave cuántica (porcentaje de coincidencia)')
KEY_GENERATION_TIME = Histogram('quantum_key_generation_seconds', 'Tiempo de generación de la clave cuántica', buckets=[0.1, 0.2, 0.5, 1, 2, 5])

# Clase para simular métricas
class MetricsSimulator:
    def __init__(self):
        self.total_attempts = 0
        self.success_attempts = 0
        self.denied_attempts = 0
    
    def simulate_access_attempt(self):
        # Simular un intento de acceso
        self.total_attempts += 1
        ACCESS_ATTEMPTS.inc()
        
        # Simular calidad de la clave (entre 50% y 100%)
        key_quality = random.uniform(0.5, 1.0)
        KEY_QUALITY.set(key_quality)
        
        # Simular tiempo de generación de la clave
        with KEY_GENERATION_TIME.time():
            time.sleep(random.uniform(0.1, 0.5))  # Simular el tiempo que toma generar la clave
        
        # Decidir si el acceso es exitoso (si la calidad de la clave es > 75%)
        if key_quality > 0.75:
            self.success_attempts += 1
            ACCESS_SUCCESS.inc()
            return True
        else:
            self.denied_attempts += 1
            ACCESS_DENIED.inc()
            return False
    
    def get_stats(self):
        return {
            "total_attempts": self.total_attempts,
            "success_attempts": self.success_attempts,
            "denied_attempts": self.denied_attempts,
            "success_rate": self.success_attempts / self.total_attempts if self.total_attempts > 0 else 0
        }

# Servidor HTTP para servir el estado actual
class StatsHandler(http.server.BaseHTTPRequestHandler):
    def __init__(self, simulator, *args, **kwargs):
        self.simulator = simulator
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        if self.path == '/stats':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            stats = self.simulator.get_stats()
            self.wfile.write(json.dumps(stats).encode())
        else:
            self.send_response(404)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'Not Found')
    
    def log_message(self, format, *args):
        # Disable logging for cleaner output
        return

def main():
    # Iniciar servidor de métricas de Prometheus
    start_http_server(9100)
    print("Servidor de métricas iniciado en el puerto 9100")
    
    # Iniciar simulador de métricas
    simulator = MetricsSimulator()
    
    try:
        while True:
            # Simular intentos de acceso periódicamente
            access_granted = simulator.simulate_access_attempt()
            print(f"Intento de acceso: {'Concedido' if access_granted else 'Denegado'}")
            
            # Esperar entre 10 y 30 segundos entre intentos
            wait_time = random.uniform(10, 30)
            print(f"Esperando {wait_time:.2f} segundos para el próximo intento...")
            time.sleep(wait_time)
    except KeyboardInterrupt:
        print("Monitor de rendimiento detenido")

if __name__ == "__main__":
    main()
