# Running the assignment in the Prayogshala Virtual Lab

**Student:** Jayaprakash · **BITS ID:** 2025AE05611

This folder is a clean copy of the project. Models, MLflow runs and figures are **not** included, so the lab VM regenerates everything from scratch. That shows the pipeline is reproducible on a fresh machine.

## 1. Open the lab
1. Go to https://prayogshala.bits-pilani.ac.in and click **Continue with BITS SSO**.
2. Launch the MLOps course lab. Wait for the VM to reach **RUNNING**, then click **Connect**.
3. On the virtual desktop, open **Terminal Emulator**.

## 2. Get the code into the persistent `workspace` folder
```bash
cd ~/workspace            # persistent folder; anything outside it is lost on terminate
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

## 5. Open in Firefox (inside the VM)
| URL | Screen |
|---|---|
| http://localhost:5050 | MLflow experiments and registry |
| http://localhost:8088/docs | API Swagger UI (through the Kubernetes Ingress) |
| http://localhost:9095/targets | Prometheus scrape targets |
| http://localhost:3030 | Grafana dashboard "Heart Disease API" |

## 6. Before leaving
- Copy anything you want to keep into `~/workspace`.
- Use **Stop VM** to resume later, or **Terminate VM** when you're finished.
