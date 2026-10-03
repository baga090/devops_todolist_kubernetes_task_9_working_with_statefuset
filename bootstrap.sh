#!/bin/bash
echo "1. Spinning up Kind cluster..."
kind create cluster --config cluster.yml

echo "2. Deploying MySQL Database Resources..."
kubectl apply -f .infrastructure/mysql/mysql-secret.yml
kubectl apply -f .infrastructure/mysql/mysql-config.yml
kubectl apply -f .infrastructure/mysql/statefulSet.yml

echo "3. Deploying Application Resources..."
kubectl apply -f .infrastructure/namespace.yml
kubectl apply -f .infrastructure/app-db-secret.yml
kubectl apply -f .infrastructure/configMap.yml
kubectl apply -f .infrastructure/secret.yml
kubectl apply -f .infrastructure/pv.yml
kubectl apply -f .infrastructure/pvc.yml
kubectl apply -f .infrastructure/deployment.yml

echo "Deployment complete! Please allow a few minutes for pods to initialize and connect."