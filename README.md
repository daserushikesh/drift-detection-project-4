# 🚀 GitOps-Based Kubernetes Application Deployment using ArgoCD

## 📖 Project Overview

This project demonstrates a complete GitOps workflow using Docker, Kubernetes, GitHub, and ArgoCD.

The application is containerized using Docker, deployed to Kubernetes, and automatically synchronized through ArgoCD whenever changes are pushed to GitHub.

---

# 🎯 Objectives

- Containerize a Flask application
- Deploy application to Kubernetes
- Implement GitOps workflow
- Configure ArgoCD Auto Sync
- Configure ArgoCD Self Heal
- Demonstrate automatic deployments through Git commits

---

# 🏗️ Architecture

```text
Developer
    │
    ▼
GitHub Repository
    │
    ▼
ArgoCD
    │
    ▼
Kubernetes Cluster
    │
    ▼
Deployment + Service
    │
    ▼
Application Pods
```

---

# 🛠️ Tech Stack

| Technology | Purpose |
|------------|----------|
| Python 3.11 | Flask Application |
| Docker | Containerization |
| Docker Hub | Image Registry |
| Kubernetes | Container Orchestration |
| Minikube | Local Kubernetes Cluster |
| kubectl | Kubernetes CLI |
| GitHub | Source Control |
| ArgoCD | GitOps Controller |

---

# 📋 Prerequisites

Before starting, install:

### Docker

```bash
docker --version
```

### kubectl

```bash
kubectl version --client
```

### Minikube

```bash
minikube version
```

### Git

```bash
git --version
```

---

# Step 1: Install Docker

## Add Docker Repository

```bash
sudo dnf -y install dnf-plugins-core

sudo dnf config-manager \
--add-repo \
https://download.docker.com/linux/fedora/docker-ce.repo
```

## Install Docker

```bash
sudo dnf install -y \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin
```

## Start Docker

```bash
sudo systemctl start docker

sudo systemctl enable docker
```

## Allow Current User

```bash
sudo usermod -aG docker $USER
```

Logout and login again.

## Verify

```bash
docker --version

docker run hello-world
```

Expected:

```text
Hello from Docker!
```

---

# Step 2: Create Project Structure

```bash
mkdir -p ~/gitops-project/app

cd ~/gitops-project/app
```

Project Structure:

```text
gitops-project/
│
├── app/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
│
└── k8s/
    ├── deployment.yaml
    └── service.yaml
```

---

# Step 3: Create Flask Application

Create:

```bash
nano app.py
```

Paste:

```python
from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return "Hello from GitOps Demo App - Version 1.0"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

Save and Exit.

---

# Step 4: Create requirements.txt

```bash
nano requirements.txt
```

Paste:

```text
flask==3.0.0
```

---

# Step 5: Create Dockerfile

```bash
nano Dockerfile
```

Paste:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
```

---

# Step 6: Build Docker Image

```bash
docker build -t gitops-demo-app:v1 .
```

Verify:

```bash
docker images
```

---

# Step 7: Run Container Locally

```bash
docker run -d \
-p 5000:5000 \
--name gitops-test \
gitops-demo-app:v1
```

Test:

```bash
curl http://localhost:5000
```

Expected:

```text
Hello from GitOps Demo App - Version 1.0
```

---

# Step 8: Push Image to Docker Hub

Login:

```bash
docker login
```

Tag:

```bash
docker tag \
gitops-demo-app:v1 \
YOUR_DOCKERHUB_USERNAME/gitops-demo-app:v1
```

Push:

```bash
docker push \
YOUR_DOCKERHUB_USERNAME/gitops-demo-app:v1
```

---

# Step 9: Install kubectl

```bash
curl -LO \
"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl

sudo mv kubectl /usr/local/bin/
```

Verify:

```bash
kubectl version --client
```

---

# Step 10: Install Minikube

```bash
curl -LO \
https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

sudo install \
minikube-linux-amd64 \
/usr/local/bin/minikube
```

Verify:

```bash
minikube version
```

---

# Step 11: Start Kubernetes Cluster

```bash
minikube start --driver=docker
```

Verify:

```bash
minikube status

kubectl get nodes
```

Expected:

```text
Ready
```

---

# Step 12–25

Continue the same format for:

- deployment.yaml creation
- service.yaml creation
- Apply manifests
- Verify Pods
- Install ArgoCD
- Expose ArgoCD UI
- Get Admin Password
- Push project to GitHub
- Create ArgoCD Application
- Enable Auto Sync
- Enable Self Heal
- Update Application v2
- Build Docker Image v2
- Push Docker Image v2
- Update deployment.yaml
- Git Commit
- Git Push
- Watch ArgoCD Deployment
- Verify Rolling Update
- Validate GitOps Workflow

---

# 🔄 GitOps Workflow

```text
Developer Changes Code
          │
          ▼
     Git Commit
          │
          ▼
      Git Push
          │
          ▼
       GitHub
          │
          ▼
       ArgoCD
          │
          ▼
    Kubernetes
          │
          ▼
 Rolling Update
          │
          ▼
 Application Updated
```

---

# 📦 Deliverables

- Flask Application
- Dockerfile
- Docker Hub Image
- Kubernetes Deployment
- Kubernetes Service
- GitHub Repository
- ArgoCD Configuration
- Auto Sync Enabled
- Self Heal Enabled

---

# 🎓 Key Learnings

- GitOps uses Git as the single source of truth.
- ArgoCD automatically synchronizes cluster state.
- Self Heal prevents configuration drift.
- Kubernetes provides zero-downtime deployments.
- Docker ensures application portability.

---

# 🤝 Contributing

Fork the repository and create a feature branch.

Submit a pull request with a detailed description of your changes.

---

# 📜 License

This project is intended for learning GitOps, Kubernetes, ArgoCD, and DevOps deployment practices.
