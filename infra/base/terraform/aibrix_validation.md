# Validation Guide: AIBrix Platform Installation

This document outlines the steps to verify that the core components of the AIBrix platform are installed and functioning correctly.

## 1. Core Components Status
Verify that all key AIBrix system pods are running.

**Command:**
```powershell
kubectl get pods -n aibrix-system
```
**Expected Output:**
*   `aibrix-controller-manager`: **Running** (1/1)
*   `aibrix-data-service`: **Running** (1/1) - *Handles dataset caching*
*   `aibrix-model-gateway`: **Running** (1/1) - *Manages inference requests*

## 2. Custom Resource Definitions (CRDs)
Confirm that AIBrix CRDs are registered in the cluster.

**Command:**
```powershell
kubectl get crds | findstr "aibrix"
```
**Expected Output (Subset):**
*   `rayclusters.ray.io` (Ray integration)
*   `modeldeployments.aibrix.ai`
*   `podgroups.scheduling.x-k8s.io` (Coscheduling)

## 3. Webhook Verification
Ensure the mutating/validating webhooks are active (critical for caching injection).

**Command:**
```powershell
kubectl get mutatingwebhookconfigurations
```
**Expected Output:**
*   Should see `aibrix-mutating-webhook-configuration`.

## 4. End-to-End Smoke Test (Optional but Recommended)
Submit a simple `Pod` or `RayCluster` that requests an AIBrix resource.

**Test Manifest `test-aibrix-job.yaml`:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: aibrix-smoke-test
  labels:
    aibrix.ai/workload: "true"
spec:
  containers:
  - name: test
    image: alpine
    command: ["sleep", "10"]
```
*   **Verification**: Check if the AIBrix controller adds sidecars or annotations to this pod.

## 5. Logs & troubleshooting
If any component is not ready, inspect logs:
```powershell
kubectl logs -n aibrix-system -l control-plane=controller-manager
```
