#!/usr/bin/env bash
# Removes what this lab created. Run with: ./teardown.sh
DEPLOY_HOME="${DEPLOY_HOME:-$HOME/deploy-lab}"
[ -x "$DEPLOY_HOME/app-ctl.sh" ] && DEPLOY_HOME="$DEPLOY_HOME" "$DEPLOY_HOME/app-ctl.sh" stop >/dev/null 2>&1
pkill -f "python3 app.py" 2>/dev/null
rm -rf "$DEPLOY_HOME"
echo "Lab environment removed."
