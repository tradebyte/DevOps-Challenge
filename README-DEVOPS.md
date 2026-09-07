# TradeByte DevOps Implementation

## Architecture

This repository delivers a robust, production-ready, and highly scalable Kubernetes deployment for the given demo application. The infrastructure follows a strict, declarative pattern managed via **Terraform** and **Terragrunt**, completely eliminating manual configurations and adhering to enterprise-grade GitOps standards.

This implementation leverages:
* **Docker:** For reliable multi-stage container packaging.
* **Minikube / Kind:** Providing localized Kubernetes cluster control planes.
* **Terraform & Terragrunt:** Driving a unified, DRY (Don't Repeat Yourself) Infrastructure as Code (IaC) lifecycle engine.
* **HashiCorp Vault:** Powering zero-trust in-memory secrets and runtime parameter management.
* **Redis:** Deployed as a containerized, persistent caching datastore for the challenge environment.
* **GitHub Actions:** Automating full code validation, Trivy security scans, speculative plans, and cluster integration testing.

### Runtime Topology & Directory Separation

To maintain strict domain isolation, the Infrastructure as Code (IaC) layer is split across three dedicated configuration modules inside the `infra/` directory:

1. **`vault.tf`:** Establishes the zero-trust secret management engine.
2. **`redis.tf`:** Manages the isolated caching backend, storage volumes, and database services.
3. **`app.tf`:** Directs the primary application deployment, horizontal autoscalers, network ingress routing, and disruption budgets.

```text
Host Machine Browser / Curl
            |
            v
   Kubernetes Service (Port-Forwarded / Localhost Tunnel)
            |
            v
    Nginx Ingress Gateway (tradebyte.local)
            |
            v
    ClusterIP Service (tradebyte-app)
            |
      +-----+-----+

      |     |     |
     app   app   app       <- 3 replicas minimum (Secure, Unprivileged UID 1000)

      |     |     |
      +-----+-----+
       /         \
      v           v
Redis Service   Vault Service

      |           |
      v           v
Redis Pod + PVC  Vault Pod  <- Single Replicas (UID 999 & UID 100)

The Horizontal Pod Autoscaler (HPA) monitors CPU utilization and dynamically 
scales the application array up to 10 instances.
```

## Security & Hardening Architecture

* **Least-Privilege & Non-Root Contexts:** Every workload in the namespace has been stripped of root execution capabilities (`runAsNonRoot = true`) to neutralize cluster-escape vulnerabilities. The application pods execute under UID `1000`, the Redis engine under UID `999`, and HashiCorp Vault under UID `100`.
* **Container Layer Defenses:** Pod definitions enforce standard `RuntimeDefault` seccomp profiles, completely block administrative privilege escalation (`allowPrivilegeEscalation = false`), and drop all Linux system kernel capabilities (`drop = ["ALL"]`).
* **Vault Zero-Privilege Patches:** To safely run HashiCorp Vault under non-root configurations without administrative kernel keys, Vault is configured to run with memory locking disabled (`disable_mlock = true`) via `VAULT_LOCAL_CONFIG` environments. Furthermore, container mount hooks skip privileged initialization checks by injecting `SKIP_CHOWN = "true"` and `SKIP_SETCAP = "true"` over localized `emptyDir` cache disks.
* **Sensitive Configuration Isolation:** Non-sensitive network properties live inside a generic `ConfigMap`, while production application secrets reside securely inside Vault's in-memory key-value data paths, shielding sensitive information from Git history leaks.

## High Availability & Autoscaling

* **Resilient Rollouts:** Application deployments employ a strict zero-downtime update pattern (`maxUnavailable = 0` and `maxSurge = 1`) to preserve 100% service availability during changes.
* **Elastic Autoscaling Arrays:** An active Horizontal Pod Autoscaler (HPA) hooks into the cluster's `metrics-server` controller, dynamically expanding the active pod footprint from **3 up to 10 replicas** if CPU demands cross a 70% utilization barrier.
* **Disruption Protections:** A Pod Disruption Budget (`tradebyte-app-pdb`) explicitly blocks cluster operations from dropping the live application footprint below a minimum threshold of **2 active running pods** simultaneously.

## Local Deployment & Task Runner Automation

The project includes a unified developer task runner menu wrapped cleanly into a **`Makefile`** to ensure a flawless Developer Experience (DX). All underlying operational automation shell scripts have been normalized to clean, lowercase, idempotent targets.

### Available Commands:

```bash
make setup          # Installs prerequisites, spins up Minikube, builds the image, and deploys everything
make status         # Displays the live running status of all pods, services, ingress routing, and HPA
make test           # Natively runs the application code unit test suite
make smoke-test     # Sends an HTTP request to verify traffic flow integrity
make fmt            # Automatically cleans and formats the Terraform code formatting blocks
make validate       # Validates Terragrunt and Terraform syntax configurations without deploying
make destroy        # Completely dismantles local resources and purges the Minikube sandbox state
```

### Accessing the App on Windows/WSL2

Because Minikube's Docker network bridge is isolated from your Windows host operating system, you can open a secure network tunnel directly into your application tier without needing Windows administrator hosts access by running:

```bash
sudo kubectl port-forward --kubeconfig=\$HOME/.kube/config --address 0.0.0.0 service/tradebyte-app 80:80 -n tradebyte
```

Leave that terminal active, open any web browser on your Windows host machine, and navigate to **`http://localhost`** to view the live dashboard and interactive visitor counter.

## CI Pipeline (GitHub Actions)

Since remote GitHub-hosted runner VMs cannot connect to a local development machine, the automated `.github/workflows/ci.yml` pipeline spins up a specialized ephemeral **Kind (Kubernetes in Docker)** cluster to run end-to-end continuous integration testing.

The robust pipeline executes across a multi-stage validation matrix:
1. **Application Verification:** Runs native Python tests using an isolated, stable **Python 3.9** environment.
2. **Security Vulnerability Scanning:** Builds the localized image and invokes an **Aqua Security Trivy Scan** to check code layers for HIGH or CRITICAL security threats.
3. **Speculative IaC Planning (Two-Phase Deploy):** Separates the Terragrunt pipeline into distinct `plan` and `apply` steps. It generates an immutable speculative plan blueprint (`-out=tfplan`) for PR audit visibility before applying anything to the cluster.
4. **Kind Cluster Provisioning:** Deploys Kind with explicit host port mappings to expose the Nginx Ingress Controller layers natively inside the GitHub runner.
5. **Transient Secret Hydration:** Automatically provisions a `metrics-server` addon and dynamically connects a script loop to hydrate the Vault server KV store with the app parameters during integration verification.
6. **Final Invariants Assertion:** Asserts that the deployment rolls out successfully, scales up to at least 3 active pods, and that the HPA reports an operational status before completing the PR merge gate.
