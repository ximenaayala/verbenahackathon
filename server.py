#!/usr/bin/env python3
"""Servidor puente para la demo VERDANA Loop.

Recibe eventos de devolucion desde la app iOS y los expone al dashboard
proyectado. Solo usa la libreria estandar: no hay nada que instalar.

Uso:
    python3 server.py

Endpoints:
    GET  /                -> dashboard.html
    POST /event           -> registra un evento (JSON)
    GET  /events          -> lista de eventos + agregados
    GET  /scan?id=XXX     -> registra por URL (plan B con tags de tipo URI)
    POST /reset           -> limpia el estado
"""

import json
import socket
import threading
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse, parse_qs

PORT = 8080
BASE_DIR = Path(__file__).resolve().parent

# Supuestos alineados con el modelo financiero del reporte.
CO2_SAVED_PER_RETURN_KG = 0.142
DEPOSIT_EUR = 0.15
SINGLE_USE_COST_EUR = 0.85
REUSE_COST_EUR = 0.37

_lock = threading.Lock()
_events = []


def _now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _record(asset_id, user="Invitado", channel="b2c_app", points=35):
    asset_id = (asset_id or "").strip()
    if not asset_id:
        return None, "asset_id vacio"

    with _lock:
        if any(e["asset_id"] == asset_id for e in _events):
            return None, "envase ya registrado"
        event = {
            "asset_id": asset_id,
            "user": user,
            "channel": channel,
            "points": points,
            "deposit": DEPOSIT_EUR,
            "co2_saved_kg": CO2_SAVED_PER_RETURN_KG,
            "timestamp": _now(),
        }
        _events.append(event)
    return event, None


def _summary():
    with _lock:
        events = list(_events)

    count = len(events)
    return {
        "events": list(reversed(events)),
        "totals": {
            "returns": count,
            "points": sum(e["points"] for e in events),
            "deposits_eur": round(count * DEPOSIT_EUR, 2),
            "co2_saved_kg": round(count * CO2_SAVED_PER_RETURN_KG, 2),
            "savings_eur": round(count * (SINGLE_USE_COST_EUR - REUSE_COST_EUR), 2),
        },
    }


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        print(f"  {self.address_string()} {fmt % args}")

    def _send(self, status, body=b"", content_type="application/json"):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        if body:
            self.wfile.write(body)

    def _send_json(self, status, payload):
        self._send(status, json.dumps(payload).encode("utf-8"))

    def do_OPTIONS(self):
        self._send(204)

    def do_GET(self):
        parsed = urlparse(self.path)

        if parsed.path in ("/", "/dashboard.html"):
            page = BASE_DIR / "dashboard.html"
            if not page.exists():
                self._send(404, b"dashboard.html no encontrado", "text/plain; charset=utf-8")
                return
            self._send(200, page.read_bytes(), "text/html; charset=utf-8")
            return

        if parsed.path == "/events":
            self._send_json(200, _summary())
            return

        if parsed.path == "/scan":
            asset_id = (parse_qs(parsed.query).get("id") or [""])[0]
            event, error = _record(asset_id, channel="nfc_uri")
            if error:
                html = f"<h2>No registrado</h2><p>{error}</p>"
            else:
                html = (
                    "<h2>Devolucion registrada</h2>"
                    f"<p>Envase {event['asset_id']}</p>"
                    f"<p>Deposito devuelto: EUR {DEPOSIT_EUR:.2f}</p>"
                )
            page = (
                "<meta name='viewport' content='width=device-width,initial-scale=1'>"
                "<body style='font-family:-apple-system,system-ui;padding:40px;text-align:center'>"
                f"{html}</body>"
            )
            self._send(200, page.encode("utf-8"), "text/html; charset=utf-8")
            return

        self._send(404, b'{"error":"not found"}')

    def do_POST(self):
        parsed = urlparse(self.path)

        if parsed.path == "/reset":
            with _lock:
                _events.clear()
            self._send_json(200, {"ok": True})
            return

        if parsed.path != "/event":
            self._send(404, b'{"error":"not found"}')
            return

        try:
            length = int(self.headers.get("Content-Length") or 0)
            data = json.loads(self.rfile.read(length) or b"{}")
        except (ValueError, json.JSONDecodeError):
            self._send_json(400, {"error": "json invalido"})
            return

        event, error = _record(
            data.get("asset_id"),
            user=data.get("user", "Invitado"),
            channel=data.get("channel", "b2c_app"),
            points=int(data.get("points", 35)),
        )

        if error:
            self._send_json(409, {"error": error})
            return

        print(f"  -> devolucion {event['asset_id']} ({event['channel']})")
        self._send_json(201, event)


def local_ip():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.connect(("8.8.8.8", 80))
        return sock.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        sock.close()


def main():
    ip = local_ip()
    print("\nVERDANA Loop — servidor puente")
    print(f"  Servidor en http://0.0.0.0:{PORT}")
    print(f"  IP en tu red: {ip}")
    print(f"  Dashboard:    http://{ip}:{PORT}/")
    print(f"  Pon esta URL en LoopStore.swift: http://{ip}:{PORT}\n")

    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServidor detenido.")
        server.server_close()


if __name__ == "__main__":
    main()
