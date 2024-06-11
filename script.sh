#!/bin/bash

set -e

# Function to clean up the Minikube cluster
function cleanup {
  echo "Stopping Minikube cluster"
  minikube stop
}
# Ensure the cleanup function runs on script exit
trap cleanup EXIT

# Start Minikube cluster
echo "Starting Minikube cluster"
minikube start

# Set Docker environment to Minikube
eval $(minikube docker-env)

# Build Docker images
echo "Building Docker images..."
docker build -t niree17/app1:latest .
docker build -t niree17/app2:latest .

# Apply Kubernetes manifests with validation turned off
echo "Applying Kubernetes manifests"
kubectl apply -f kubernetes/application1-deployment.yaml --validate=false
kubectl apply -f kubernetes/application1-service.yaml --validate=false
kubectl apply -f kubernetes/application2-deployment.yaml --validate=false
kubectl apply -f kubernetes/application2-service.yaml --validate=false

# Wait for deployments to be ready
echo "Waiting for application1-deployment to be ready..."
kubectl rollout status deployment/application1-deployment || { echo "application1-deployment failed to roll out"; exit 1; }

echo "Waiting for application2-deployment to be ready..."
kubectl rollout status deployment/application2-deployment || { echo "application2-deployment failed to roll out"; exit 1; }

# Verify services
echo "Verifying services"
kubectl get svc

# Get the URLs of the services
APP1_URL=$(minikube service application1-service --url)
APP2_URL=$(minikube service application2-service --url)

# Print HTTP responses of applications
echo "Application 1 URL: $APP1_URL"
echo "Application 2 URL: $APP2_URL"

# Test services
echo "Testing application1-service..."
curl $APP1_URL

echo "Testing application2-service..."
curl $APP2_URL


