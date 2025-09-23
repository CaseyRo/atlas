
# 🌐 Atlas - Network Infrastructure Visualizer (Go-powered)

**Atlas** is a full-stack containerized tool to **scan**, **analyze**, and **visualize** network infrastructure dynamically. Built with Go, FastAPI, NGINX, and a custom React frontend, it provides automated scanning, storage, and rich dashboards for insight into your infrastructure.

---
### Live Demo 🔗 [atlasdemo.vnerd.nl](https://atlasdemo.vnerd.nl/)

---
## 🚀 What It Does

Atlas performs three key functions:

1. **Scans Docker Containers** running on the host to extract:
   - IP addresses
   - MAC addresses
   - Open ports
   - Network names
   - OS type (from image metadata)

2. **Scans Local & Neighboring Hosts** on the subnet to:
   - Detect reachable devices
   - Retrieve OS fingerprints, MACs, and open ports
   - Populate a full map of the infrastructure

3. **Visualizes Data in Real-Time**:
   - Serves an interactive HTML dashboard via Nginx
   - Hosts a FastAPI backend for data access and control
   - Uses a React frontend to render dynamic network graphs

---

## 🖼️ Screenshots

### Dashboard View

<div style="display: flex; gap: 24px; flex-wrap: wrap;">
  <a href="screenshots/network-map-1.png" target="_blank">
    <img src="screenshots/network-map-1.png" alt="Atlas Dashboard 1" width="300"/>
  </a>
  <a href="screenshots/network-map-2.png" target="_blank">
    <img src="screenshots/network-map-2.png" alt="Atlas Dashboard 2" width="300"/>
  </a>
</div>

### Hosts Table

<div style="display: flex; gap: 24px; flex-wrap: wrap;">
  <a href="screenshots/hosts-table-1.png" target="_blank">
    <img src="screenshots/hosts-table-1.png" alt="Hosts Table 1" width="300"/>
  </a>
  <a href="screenshots/hosts-table-2.png" target="_blank">
    <img src="screenshots/hosts-table-2.png" alt="Hosts Table 2" width="300"/>
  </a>
</div>

### Vis Dashboard (dev)

<div style="display: flex; gap: 24px; flex-wrap: wrap;">
  <a href="screenshots/vis.png" target="_blank">
    <img src="screenshots/vis.png" alt="Network Graph" width="300"/>
  </a>
</div>

---

## 🚀 Deployment (Docker)

Run the Atlas stack with:

```bash
docker run -d \
  --name atlas \
  --network=host \
  --cap-add=NET_RAW \
  --cap-add=NET_ADMIN \
  -v /var/run/docker.sock:/var/run/docker.sock \
  keinstien/atlas:latest
```

📌 This will:

Expose the UI on http://localhost:8888

Launch backend API at http://localhost:8889

Auto-scan Docker + local subnet on container start

---

## ⚙️ How it Works

### 🔹 Backend Architecture

- **Go CLI (`atlas`)**
  - Built using Go 1.22
  - Handles:
    - `initdb`: Creates SQLite DB with required schema
    - `fastscan`: Fast host scan using ARP/Nmap
    - `dockerscan`: Gathers Docker container info from `docker inspect`
    - `deepscan`: Enriches data with port scans, OS info, etc.

- **FastAPI Backend**
  - Runs on `port 8889`
  - Serves:
    - `/api/hosts` – all discovered hosts (regular + Docker)
    - `/api/external` – external IP and metadata

- **NGINX**
  - Serves frontend (React static build) on `port 8888`
  - Proxies API requests (`/api/`) to FastAPI (`localhost:8889`)

---

## 📂 Project Structure

**Source Code (Host Filesystem)**

```
atlas/
├── config/
│   ├── atlas_go/        # Go source code (main.go, scan, db)
│   ├── bin/             # Compiled Go binary (atlas)
│   ├── db/              # SQLite file created on runtime
│   ├── logs/            # Uvicorn logs
│   ├── nginx/           # default.conf for port 8888
│   └── scripts/         # startup shell scripts
├── data/
│   ├── html/            # Static files served by Nginx
│   └── react-ui/        # Frontend source (React)
├── Dockerfile
├── LICENSE
└── README.md
```

**Inside Container (/config)**
```
/config/
├── bin/atlas             # Go binary entrypoint
├── db/atlas.db           # Persistent SQLite3 DB
├── logs/                 # Logs for FastAPI
├── nginx/default.conf    # Nginx config
└── scripts/atlas_check.sh # Entrypoint shell script

```

---

## 🧪 React Frontend (Dev Instructions)

This is a new React-based UI.

### 🛠️ Setup and Build

```bash
cd /swarm/data/atlas/react-ui
npm install
npm run build
```

The built output will be in:
```
/swarm/data/atlas/react-ui/dist/
```

For development CI/CD (for UI and backend anf build a new docker version):
```bash
/swarm/github-repos/atlas/deploy.sh
```


## 🚀 CI/CD: Build and Publish a New Atlas Docker Image

To deploy a new version and upload it to Docker Hub, use the provided CI/CD script:

1. Build and publish a new image:

   ```bash
   /swarm/github-repos/atlas/deploy.sh
   ```

   - The script will prompt you for a version tag (e.g. `v3.2`).
   - It will build the React frontend, copy to NGINX, build the Docker image, and push **both** `keinstien/atlas:$VERSION` and `keinstien/atlas:latest` to Docker Hub.

2. Why push both tags?

   - **Version tag:** Allows you to pin deployments to a specific release (e.g. `keinstien/atlas:v3.2`).
   - **Latest tag:** Users can always pull the most recent stable build via `docker pull keinstien/atlas:latest`.

3. The script will also redeploy the running container with the new version.

**Example output:**
```shell
🔄 Tagging Docker image as latest
📤 Pushing Docker image to Docker Hub...
✅ Deployment complete for version: v3.2
```

> **Note:** Make sure you are logged in to Docker Hub (`docker login`) before running the script.

### 🐳 Multi-arch Docker builds (arm64 focus)

Atlas ships with two Dockerfiles:

- `Dockerfile` – default x86_64/amd64 build used for `keinstien/atlas:latest`
- `Dockerfile.arm64` – mirrors the main recipe but pins the toolchain to ARM64

The sections below show common ways to produce an ARM64 image, but you can freely swap the `--platform` flag to build other architectures (e.g. `linux/amd64`, `linux/arm/v7`).

#### 1. Build directly on an ARM64 workstation (Apple Silicon, Graviton, etc.)

```bash
docker build \
  -f Dockerfile.arm64 \
  -t keinstien/atlas:arm64-local .
```

This route keeps all layers on the machine you run the command from—perfect when you only need a local test container.

#### 2. Cross-build locally using Docker Buildx

```bash
docker buildx create --name atlas-builder --use
docker buildx build --platform linux/arm64 \
  -f Dockerfile.arm64 \
  -t keinstien/atlas:arm64 \
  --load .
```

Passing `--load` places the finished image into your local Docker cache so you can `docker run` it immediately. Swap `--load` for `--push` if you want to publish straight to Docker Hub as part of CI.

#### 3. Cross-build on a remote builder (useful for CI runners)

```bash
# Point Buildx at an SSH-accessible ARM host or a remote Docker context
docker buildx create --name atlas-remote --driver docker-container \
  --platform linux/arm64 \
  ssh://user@arm-host --use

docker buildx build --platform linux/arm64 \
  -f Dockerfile.arm64 \
  -t registry.example.com/atlas:arm64 \
  --push .
```

The remote builder receives the source context, performs the build natively, and pushes the result to your registry without copying large layers back to your workstation.

> ℹ️ `deploy.sh` automates steps similar to the above when publishing releases—it compiles the React UI, syncs static assets, and builds/pushes both amd64 and arm64 images.

To verify cross-platform compatibility you can swap `--platform` to other targets and retag the output (such as `keinstien/atlas:amd64`). The resulting containers continue to boot via `atlas_check.sh`, just like the primary image.

### 🔧 Changing the NGINX/UI port

Atlas serves the React UI through NGINX. Because Atlas requires host network access, you can't rely on standard Docker port mappings to change the UI port. Instead, adjust the port that NGINX listens on inside the container:

**Change the NGINX listen port inside the container:**

   ```bash
   docker run -d \
     -e ATLAS_UI_PORT=3000 \
     -p 3000:3000 \
     --name atlas \
     keinstien/atlas:latest
   ```

   `atlas_check.sh` renders `/etc/nginx/conf.d/default.conf` from `config/nginx/default.conf.template`, so setting `ATLAS_UI_PORT` updates the NGINX `listen` directives at runtime. Because the container joins the host network, the UI will now be available on `http://localhost:3000` without additional port remapping.

If you modify the baked-in defaults (e.g. in `Dockerfile*` or `config/nginx/default.conf.template`), update the README and any deployment scripts so the new port is documented everywhere.


---

## 🌍 URLs

- **Swagger API docs:**
  - `🌍 http://localhost:8888/api/docs` (Host Data API endpoint)

- **Frontend UI:**
  - `🖥️ UI	http://localhost:8888/` (main dashboard)
  - `📊 http://localhost:8888/hosts.html` (Hosts Table)
  - `🧪 http://localhost:8888/visuals/vis.js_node_legends.html` (legacy test UI)

> Default exposed port is: `8888`

---

## ✅ Features

- [x] Fast network scans (ping/ARP)
- [x] Docker container inspection
- [x] External IP discovery
- [x] Deep port scans with OS enrichment
- [x] React-based dynamic frontend
- [x] NGINX + FastAPI routing
- [x] SQLite persistence
- [x] Scheduled auto scans using Go timers

---

## 📌 Dev Tips

To edit Go logic:
- Main binary: `internal/scan/`
- Commands exposed via: `main.go`

To edit API:
- Python FastAPI app: `scripts/app.py`

To edit UI:
- Modify React app under `/react-ui`
- Rebuild and copy static files to `/html`
- _automated deplolyment and publish to dockerhub using the script deploy.sh_
---

## ⚙️ Automation Notes
- Atlas runs automatically on container start.

- All Go scan tasks run sequentially:
   - `initdb → fastscan → deepscan → dockerscan`

- Scheduled scans are run every 30 minutes via Go timers.

- No cron dependency required inside the container.

- Scans can also be manually triggered via the UI using API post request.
---
## 👨‍💻 Author

**Karam Ajaj**  
Infrastructure & Automation Engineer  
[https://github.com/karam-ajaj](https://github.com/karam-ajaj)

---

## 📝 License

MIT License — free for personal or commercial use.

---

## 🤝 Contributing

Suggestions, bug reports, and pull requests are welcome!

