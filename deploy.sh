#!/bin/bash
set -euo pipefail

echo "🔧 Atlas CI/CD Deployment Script"

# Resolve repo root from this script's location
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="keinstien/atlas"
CONTAINER_NAME="atlas"

echo "📁 Repo root: $REPO_ROOT"

# Prompt for version
read -p "👉 Enter the version tag (e.g. v3.3): " VERSION
if [[ -z "${VERSION:-}" ]]; then
  echo "❌ Version tag is required. Exiting..."
  exit 1
fi

# Ask whether to also tag this version as 'latest'
read -p "👉 Tag this version as 'latest' as well? (y/N): " TAG_LATEST
if [[ "${TAG_LATEST:-}" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  DO_LATEST=true
else
  DO_LATEST=false
fi

# Sanity checks
command -v docker >/dev/null 2>&1 || { echo "❌ docker is not installed or not in PATH"; exit 1; }

echo "📦 Starting deployment for version: $VERSION"
COMMIT_SHA="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo 'dirty')"
BUILD_TIME="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

# Step 3: Stop and remove existing container if present
echo "🧹 Removing existing '$CONTAINER_NAME' container if running..."
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

# Step 4: (Optional) backup disabled by default. Enable by exporting RUN_BACKUP=1
if [[ "${RUN_BACKUP:-0}" == "1" && -x "/home/karam/atlas-repo-backup.sh" ]]; then
  echo "🗃️ Running backup script..."
  /home/karam/atlas-repo-backup.sh || echo "⚠️ Backup script returned non-zero exit; continuing..."
else
  echo "ℹ️ Skipping backup (set RUN_BACKUP=1 to enable and ensure script exists)"
fi

# Step 5: Build Docker image from repo root
echo "🐳 Building Docker image: $IMAGE:$VERSION"
DOCKER_BUILDKIT=1 docker build \
  --build-arg BUILD_VERSION="$VERSION" \
  --build-arg BUILD_COMMIT="$COMMIT_SHA" \
  --build-arg BUILD_TIME="$BUILD_TIME" \
  -t "$IMAGE:$VERSION" "$REPO_ROOT"

# Step 5b: Optionally tag as latest
if $DO_LATEST; then
  echo "🔄 Tagging Docker image as latest"
  docker tag "$IMAGE:$VERSION" "$IMAGE:latest"
else
  echo "⏭️ Skipping 'latest' tag per selection"
fi

# Step 6: Push image(s) to Docker Hub
echo "📤 Pushing Docker image(s) to Docker Hub..."
docker push "$IMAGE:$VERSION"
if $DO_LATEST; then
  docker push "$IMAGE:latest"
fi

# Step 7: Run new container
echo "🚀 Deploying container..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --network=host \
  --cap-add=NET_RAW \
  --cap-add=NET_ADMIN \
  -v /var/run/docker.sock:/var/run/docker.sock \
  "$IMAGE:$VERSION"

if $DO_LATEST; then
  echo "✅ Deployment complete for version: $VERSION (also tagged as latest)"
else
  echo "✅ Deployment complete for version: $VERSION"
fi