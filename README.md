
# 🌐 Atlas - Network Infrastructure Visualizer (Go-powered)

**Atlas** is a full-stack containerized tool to **scan**, **analyze**, and **visualize** network infrastructure dynamically. Built with Go, FastAPI, NGINX, and a custom React frontend, it provides automated scanning, storage, and rich dashboards for insight into your infrastructure.

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

Launch backend API at http://localhost:8888/api/...

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

Copy build to NGINX HTML volume:

```bash
cp -r dist/* /swarm/data/atlas/html/
```

For development structure:
```bash
mv /swarm/data/atlas/react-ui /swarm/data/atlas-dev/
```

---

## 🌍 URLs

- **API Endpoints:**
  - `🧠 http://localhost:8888/api/hosts` (Host Data API endpoint)
  - `🌍 http://localhost:8888/api/external` (External IP API endpoint)

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

