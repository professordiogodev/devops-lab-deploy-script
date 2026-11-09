#!/usr/bin/env bash
# Prepares the release shelf and the app controller in $DEPLOY_HOME (default ~/deploy-lab). Re-run to start over.
set -euo pipefail
command -v python3 >/dev/null || { echo "python3 is required (sudo apt install python3)"; exit 1; }
DEPLOY_HOME="${DEPLOY_HOME:-$HOME/deploy-lab}"
[ -x "$DEPLOY_HOME/app-ctl.sh" ] && "$DEPLOY_HOME/app-ctl.sh" stop >/dev/null 2>&1 || true
rm -rf "$DEPLOY_HOME"; mkdir -p "$DEPLOY_HOME/incoming" "$DEPLOY_HOME/releases"

mkrel() { # version healthy(1/0)
  local d="$DEPLOY_HOME/incoming/$1"; mkdir -p "$d"; echo "${1#v}" > "$d/VERSION"
  cat > "$d/app.py" <<'P'
import http.server, os, socketserver, sys
here = os.path.dirname(os.path.abspath(__file__))
version = open(os.path.join(here, "VERSION")).read().strip()
healthy = os.path.exists(os.path.join(here, "UNHEALTHY")) is False
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            code = 200 if healthy else 500
            body = ('{"status":"%s","version":"%s"}' % ("ok" if healthy else "error", version)).encode()
        else:
            code = 200; body = b"Clipstr " + version.encode()
        self.send_response(code); self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)
    def log_message(self, *a): pass
socketserver.TCPServer.allow_reuse_address = True
http.server.HTTPServer(("127.0.0.1", 8090), H).serve_forever()
P
  [ "$2" = 1 ] || touch "$d/UNHEALTHY"
}
mkrel v1.0.0 1; mkrel v1.1.0 1; mkrel v1.2.0 0; mkrel v1.3.0 1; mkrel v1.4.0 1; mkrel v1.5.0 1

cat > "$DEPLOY_HOME/app-ctl.sh" <<'C'
#!/usr/bin/env bash
# Controls the app that runs from $DEPLOY_HOME/current.  usage: app-ctl.sh start|stop|restart|status
H="${DEPLOY_HOME:-$HOME/deploy-lab}"; PID="$H/app.pid"
stop() { [ -f "$PID" ] && kill "$(cat "$PID")" 2>/dev/null; rm -f "$PID"; pkill -f "python3 app.py" 2>/dev/null || true; sleep 0.3; }
start() { [ -e "$H/current/app.py" ] || { echo "no current release" >&2; return 1; }
          cd "$H/current/" && setsid nohup python3 app.py >"$H/app.log" 2>&1 & echo $! > "$PID"; sleep 0.8; }
case "${1:-}" in
  start) start ;; stop) stop ;; restart) stop; start ;;
  status) if curl -fs --max-time 2 http://127.0.0.1:8090/healthz >/dev/null; then echo "healthy"; else echo "not healthy"; exit 1; fi ;;
  *) echo "usage: app-ctl.sh start|stop|restart|status"; exit 2 ;;
esac
C
chmod +x "$DEPLOY_HOME/app-ctl.sh"
echo "Ready in $DEPLOY_HOME"
echo "  incoming/   the built releases waiting to be deployed: $(ls "$DEPLOY_HOME/incoming" | tr '\n' ' ')"
echo "  releases/   where deployed releases live (empty)"
echo "  app-ctl.sh  start/stop/restart/status of the app that runs from the 'current' symlink"
echo "Your task: write deploy.sh in this repository. See README.md."
