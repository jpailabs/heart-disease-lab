# Running the assignment in the Prayogshala Virtual Lab

**Student:** Jayaprakash · **BITS ID:** 2025AE05611

This folder is a clean copy of the project. Models, MLflow runs and figures are **not** included, so the lab VM regenerates everything from scratch. That shows the pipeline is reproducible on a fresh machine.

## 1. Open the lab
1. Go to https://prayogshala.bits-pilani.ac.in and click **Continue with BITS SSO**.
2. Launch the MLOps course lab. Wait for the VM to reach **RUNNING**, then click **Connect**.
3. On the virtual desktop, open **Terminal Emulator**.

## 2. Get the code
`~/workspace` is persistent, but it's an AWS EFS network mount and slow for thousands of small files (a Python venv). So run from the VM's local disk, and save the results to `~/workspace` at the end (`./run_lab.sh save`, which is also the last step of a full run).
```bash
cd ~
git clone https://github.com/jpailabs/heart-disease-lab.git
cd heart-disease-lab
```

## 3. One-time setup (Python, Docker, kubectl, kind)
Works on the Prayogshala Rocky Linux 9 image (dnf) and on Ubuntu (apt). It installs only what is missing; on the MLOps VM that is just `kubectl` and `kind`.
```bash
./lab_setup.sh
```

## 4. Run the pipeline
```bash
./run_lab.sh              # all steps
./run_lab.sh train        # or a single step: env data eda train test docker k8s smoke mlflow status
```

| Step | What it shows |
|---|---|
| `env` | clean install from `requirements.txt` |
| `data` | download from UCI and cleaning |
| `eda` | EDA figures in `reports/figures/` |
| `train` | tuning of 3 models with MLflow tracking and the model registry |
| `test` | flake8 and 22 pytest unit tests with coverage |
| `docker` | image build, container run and a `/predict` call |
| `k8s` | kind cluster, Ingress, 2 API replicas, Prometheus and Grafana |
| `smoke` | 100 predictions through the Ingress plus a validation (422) check |
| `mlflow` | starts the MLflow UI |
| `status` | `kubectl` resources and the URLs to open |
| `save` | copies the results (models, MLflow store, figures) to `~/workspace/heart-disease-lab-results` |

## 5. Open in Firefox (inside the VM)
| URL | Screen |
|---|---|
| http://localhost:5050 | MLflow experiments and registry |
| http://localhost:8088/docs | API Swagger UI (through the Kubernetes Ingress) |
| http://localhost:9095/targets | Prometheus scrape targets |
| http://localhost:3030 | Grafana dashboard "Heart Disease API" |

## 6. Before leaving
- Run `./run_lab.sh save` so the results are copied to `~/workspace`.
- Use **Stop VM** to resume later, or **Terminate VM** when you're finished.

## Lab run evidence (Prayogshala VM, 19 Oct 2026)

The full pipeline was run on the Prayogshala virtual lab: Rocky Linux 9.5, 4 vCPU, 15 GB RAM, user `s2025ae05611`. The results matched the original runs exactly (CV ROC-AUC 0.9075, test ROC-AUC 0.9589), which confirms reproducibility on a clean machine.

| # | Screenshot | Shows |
|---|---|---|
| 00 | `lab_00_vm_desktop.png` | Prayogshala virtual desktop |
| 01 | `lab_01_clone_repo.png` | repository cloned in the lab |
| 02 | `lab_02a_setup_install.png`, `lab_02b_setup_tools_ready.png` | `lab_setup.sh`: dnf packages, kubectl, kind, Docker ready |
| 03 | `lab_03_python_env.png` | clean venv from `requirements.txt` (1 min 21 s) |
| 04 | `lab_04_data_download.png` | UCI download and cleaning (303 rows) |
| 05 | `lab_05_eda.png` | EDA figures and summary stats |
| 06 | `lab_06_training_mlflow.png` | tuning 3 models, MLflow tracking, model registry v1 |
| 07 | `lab_07a_lint_tests.png`, `lab_07b_tests_coverage.png` | flake8 clean; 22/22 pytest passed with coverage |
| 08 | `lab_08_docker_build_run.png` | Docker image build, container run, `/predict` |
| 09 | `lab_09_kubernetes_deploy.png` | kind cluster, ingress-nginx, 2 API replicas, Prometheus and Grafana |
| 10 | `lab_10_smoke_test_logs.png` | 100/100 predictions via Ingress, 422 validation, JSON request logs |
| 11 | `lab_11_kubectl_status.png` | `kubectl get all,ingress` and monitoring pods |
| 12 | `lab_12_mlflow_experiment.png` | MLflow experiment (80 runs) |
| 13 | `lab_13a/b/c_*.png` | selected run: lab user, params, metrics, artifacts, registry |
| 14 | `lab_14a/b_*.png` | Swagger UI via Ingress; live `/predict` call (HTTP 200) |
| 15 | `lab_15_prometheus_targets.png` | Prometheus: both pods UP |
| 16 | `lab_16a/b_*.png` | Grafana dashboard under load |
| 17 | `lab_17_results_saved_workspace.png` | results copied to the persistent `~/workspace` |

**Notes from the lab run**
- `~/workspace` is an AWS EFS (NFS) mount, which makes `pip install` there very slow. Run from `~` and use `./run_lab.sh save` to keep the results.
- The VM screen locks after a few idle minutes. To turn this off for the session:
  ```bash
  for p in /lock/enabled /saver/enabled; do xfconf-query -c xfce4-screensaver -p $p -n -t bool -s false; done; pkill xfce4-screensaver
  ```
