import os
import socket
import sys
import time
from http.server import HTTPServer, BaseHTTPRequestHandler

APP_VERSION = os.getenv("APP_VERSION", "v1-good")
STARTUP_DELAY = int(os.getenv("STARTUP_DELAY", "0"))
CRASH_ON_START = os.getenv("CRASH_ON_START", "false").lower() == "true"
HEALTH_STATUS = int(os.getenv("HEALTH_STATUS", "200"))
PORT = int(os.getenv("PORT", "8080"))
HOSTNAME = socket.gethostname()
START_TIME = time.time()

# Scenario B trigger: Immediate crash on boot
if CRASH_ON_START:
    print(f"[{HOSTNAME}] FATAL: Container crash triggered on startup! Exiting with code 1...", file=sys.stderr)
    sys.exit(1)

class RollbackHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        uptime = time.time() - START_TIME

        # Health check endpoint used by Nomad & Consul
        if self.path == "/health":
            # Scenario C trigger: Delay readiness beyond deadline
            if uptime < STARTUP_DELAY:
                self.send_response(503)
                self.send_header("Content-type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"status": "warming_up"}\n')
            # Scenario A trigger: Explicit health check failure
            elif HEALTH_STATUS != 200:
                self.send_response(HEALTH_STATUS)
                self.send_header("Content-type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"status": "unhealthy", "code": 503}\n')
            else:
                self.send_response(200)
                self.send_header("Content-type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"status": "healthy"}\n')
        else:
            # Normal application traffic
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            response = f"App: Rollback-Test | Version: {APP_VERSION} | Instance: {HOSTNAME}\n"
            self.wfile.write(response.encode())

    def log_message(self, format, *args):
        return

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), RollbackHandler)
    print(f"Server started on port {PORT} | Version: {APP_VERSION}")
    server.serve_forever()