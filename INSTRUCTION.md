# MySQL StatefulSet & Django Application Deployment

## 1. How to deploy all resources
Run the provided bootstrap script. It will automatically spin up a local Kubernetes cluster using `kind`, deploy the MySQL database via StatefulSet, and spin up the Django application connected to this database.
```bash
sh bootstrap.sh
```

## 2. Architecture & Best Practices Rationale
The deployment aligns with Kubernetes best practices for stateful workloads:
* **StatefulSet vs Deployment:** Unlike stateless Deployments, we use a `StatefulSet` for MySQL to guarantee strict ordering (0 -> 1 -> 2), stable network identities (e.g., `mysql-0`), and dedicated persistent storage for each pod via `volumeClaimTemplates`.
* **Headless Service:** A Headless Service (`clusterIP: None`) is implemented for the database. Instead of load-balancing traffic randomly across all DB pods, it creates specific DNS records, allowing our Django application to reliably connect to the primary database pod at `mysql-0.mysql-headless.mysql.svc.cluster.local`.
* **Security & Secrets:** Sensitive database credentials (user, password, root password) are strictly decoupled from the application code and manifests. They are stored in K8s `Secret` resources and injected into the containers as environment variables.

## 3. Validation of changes

### Step A: Validate MySQL StatefulSet
Verify that the StatefulSet successfully provisioned the database pods with stable identifiers:
```bash
kubectl get statefulsets -n mysql
kubectl get pods -n mysql -o wide
```
*Expected Output:* You should see `mysql-0`, `mysql-1`, and `mysql-2` in the `Running` state.

### Step B: Validate Database Initialization
Confirm that the database was correctly initialized via the `init.sql` script mounted from the ConfigMap into `/docker-entrypoint-initdb.d`:
```bash
kubectl logs mysql-0 -n mysql
```
*Expected Output:* The logs should indicate that `tododb` was created and privileges were granted to `todouser`.

### Step C: Validate Application Connection
Ensure the Django application pods are running and successfully reading the database credentials from the `app-db-secret`:
```bash
# 1. Verify app pods are running
kubectl get pods -n mateapp

# 2. Get the name of an application pod
kubectl get pods -n mateapp -l app=todolist

# 3. Check the injected database environment variables (Replace <pod-name>)
kubectl exec -it <pod-name> -n mateapp -- env | grep DB_
```
*Expected Output:* The variables `DB_NAME`, `DB_USER`, `DB_PASSWORD`, and `DB_HOST` (pointing to `mysql-0`) should be printed to the console, confirming successful Secret injection.