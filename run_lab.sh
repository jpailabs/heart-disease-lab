#!/usr/bin/env bash
# Run the whole assignment pipeline inside the lab VM, step by step.
# Run from the VM's local disk (e.g. ~/heart-disease-lab): ~/workspace is a slow network (EFS) mount.
# Usage: ./run_lab.sh            (all steps)
#        ./run_lab.sh <step>     (one of: env data eda train test docker k8s smoke mlflow status save)
set -euo pipefail
cd "$(dirname "$0")"
PY=.venv/bin/python

# Pinned packages (numpy 1.26, mlflow 2.17/pyarrow) need Python 3.10-3.12.
pick_python() {
  for c in ${PYTHON:-} python3.11 python3.12 python3.10 python3; do
    command -v "$c" >/dev/null 2>&1 || continue
    if "$c" -c 'import sys; sys.exit(0 if (3,10) <= sys.version_info[:2] <= (3,12) else 1)'; then
      echo "$c"; return
    fi
  done
  echo "No Python 3.10-3.12 found - run ./lab_setup.sh first" >&2; exit 1
}
banner() { printf '\n\033[1;32m==================== %s ====================\033[0m\n' "$*"; }

step_env() {
  banner "1. Python environment (clean install from requirements.txt)"
  [ -d .venv ] || "$(pick_python)" -m venv .venv
  .venv/bin/pip install -q --upgrade pip
  .venv/bin/pip install -q -r requirements.txt
  .venv/bin/pip install -q -e .
  $PY --version; .venv/bin/pip list 2>/dev/null | grep -iE "^(scikit-learn|pandas|mlflow|fastapi) " || true
}
step_data()  { banner "2. Data acquisition + cleaning"; $PY scripts/download_data.py --force; }
step_eda()   { banner "3. EDA figures"; $PY -m heart.eda | head -30; ls reports/figures; }
step_train() {
  banner "4. Training + tuning + MLflow tracking"
  $PY -m heart.train --register 2>&1 | grep -E "heart.train|Registered|Created version"
  head -25 models/model_metadata.json
}
step_test()  {
  banner "5. Lint + unit tests"
  $PY -m flake8 src api tests scripts --count --statistics && echo "flake8: 0 issues"
  $PY -m pytest -v -p no:warnings --cov=src/heart --cov=api
}
step_docker() {
  banner "6. Docker build + run + /predict"
  docker build -t heart-api:1.0.0 -t heart-api:latest .
  docker rm -f heart-api-lab >/dev/null 2>&1 || true
  docker run -d --name heart-api-lab -p 8090:8000 heart-api:1.0.0
  for i in $(seq 1 30); do curl -sf localhost:8090/ready >/dev/null && break; sleep 1; done
  curl -s localhost:8090/health; echo
  curl -s -X POST localhost:8090/predict -H 'content-type: application/json' -d @sample_request.json; echo
  docker ps --filter name=heart-api-lab
}
step_k8s()   { banner "7. Kubernetes (kind) deployment + monitoring"; ./scripts/deploy_kind.sh; }
step_smoke() { banner "8. Endpoint verification via Ingress"; ./scripts/smoke_test.sh http://localhost:8088 100; }
step_mlflow() {
  banner "9. MLflow UI"
  pkill -f "mlflow ui" 2>/dev/null || true
  nohup .venv/bin/mlflow ui --backend-store-uri sqlite:///mlflow.db --default-artifact-root ./mlruns \
        --host 127.0.0.1 --port 5050 > mlflow-ui.log 2>&1 &
  sleep 5; echo "MLflow UI: http://localhost:5050"
}
step_save() {
  # ~/workspace is the persistent (EFS) folder; copy results there, skipping the venv.
  banner "Save results to ~/workspace"
  DEST=~/workspace/heart-disease-lab-results
  mkdir -p "$DEST"
  rsync -a --exclude .venv --exclude .git --exclude '__pycache__' ./ "$DEST"/
  ls "$DEST"; echo "saved to $DEST"
}
step_status() {
  banner "Status"
  kubectl get nodes; echo; kubectl get all,ingress -n heart-mlops; echo; kubectl get pods,svc -n monitoring
  echo; echo "Open in Firefox:"
  echo "  Web API docs  http://localhost:8088/docs"
  echo "  MLflow        http://localhost:5050"
  echo "  Prometheus    http://localhost:9095/targets"
  echo "  Grafana       http://localhost:3030"
}

if [ $# -gt 0 ]; then "step_$1"; exit; fi
for s in env data eda train test docker k8s smoke mlflow status save; do "step_$s"; done
banner "ALL STEPS COMPLETED"
