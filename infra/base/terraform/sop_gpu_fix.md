# SOP: G5/GPU Quota & AIBrix Configuration Fix

## 1. Issue Description
*   **Problem**: Karpenter was trying to provision instance types (e.g., `g5.12xlarge`, `g5.48xlarge`) that exceeded the AWS Service Quota.
*   **Symptom**: Pods remained `Pending`. Karpenter logs showed "could not schedule pod" or "no instance type met requirements".
*   **Secondary Issue**: The `nvidia-device-plugin` Garbage Collector (GC) pod failed to schedule on GPU nodes because it lacked the necessary `tolerations`.

## 2. resolution Actions

### Step 1: Restrict Instance Types
We restricted the Karpenter NodePool to only use instance types that fit the quota and workload.

**Command Executed:**
```bash
kubectl patch nodepool g5-nvidia --type='merge' -p '{"spec":{"template":{"spec":{"requirements":[{"key":"karpenter.k8s.aws/instance-type","operator":"In","values":["g5.large","g5.2xlarge"]},{"key":"karpenter.k8s.aws/instance-family","operator":"In","values":["g5"]},{"key":"karpenter.sh/capacity-type","operator":"In","values":["on-demand","spot"]}]}}}}'
```
*   **Effect**: Forces Karpenter to ONLY consider `g5.large` (1 GPU) and `g5.2xlarge` (1 GPU).

### Step 2: Fix Scheduling (Tolerations)
We patched the `nvidia-device-plugin` ArgoCD Application to add tolerations for the generic GPU taint.

**Command Executed:**
```bash
kubectl patch app -n argocd nvidia-device-plugin --type=merge --patch-file nvidia-patch.yaml
```
**Patch Content (`nvidia-patch.yaml`):**
```yaml
spec:
  source:
    helm:
      values: |
        nfd:
          gc:
            tolerations:
              - key: nvidia.com/gpu
                operator: Exists
                effect: NoSchedule
```
*   **Why?**: GPU nodes are automatically tainted with `nvidia.com/gpu:NoSchedule` by the cloud provider or Karpenter to prevent non-GPU workloads from running on expensive hardware.
*   **The Problem**: The NVIDIA Garbage Collector (GC) pod needs to run on these nodes to clean up resources, but it didn't have the permission (toleration) to ignore that taint, so it stayed stuck in `Pending`.
*   **The Fix**: We added the toleration, allowing the GC pod to "tolerate" the taint and schedule successfully.

## 3. Configuration Diffs

### Karpenter NodePool (`nodepool.tpl`)
We modified the template to restrict instance types when `g5` is selected.

```diff
       requirements:
+%{ if instance_family == "g5" ~}
+        - key: karpenter.k8s.aws/instance-type
+          operator: In
+          values:
+            - "g5.large"
+            - "g5.2xlarge"
+%{ else ~}
         - key: karpenter.k8s.aws/instance-family
           operator: In
           values:
             - ${instance_family}
+%{ endif ~}
```

### NVIDIA Device Plugin (`nvidia-device-plugin.yaml`)
We patched the ArgoCD application (via `kubectl` or Terraform) to include tolerations for the Garbage Collector (GC).

```diff
           gc:
             nodeSelector:
               karpenter.k8s.aws/instance-gpu-manufacturer: nvidia
+            tolerations:
+              - key: nvidia.com/gpu
+                operator: Exists
+                effect: NoSchedule
```

## 4. Verification
1.  **Check NodePool**:
    ```powershell
    kubectl get nodepool g5-nvidia -o jsonpath='{.spec.template.spec.requirements}'
    ```
    *Result*: confirmed distinct list `["g5.large", "g5.2xlarge"]`.
2.  **Check Pods**:
    ```powershell
    kubectl get pods -n nvidia-device-plugin
    ```
    *Result*: All pods, including `nfd-gc`, are `Running`.

## 5. Workload Validation (G6e)
*   **Validation**: Confirmed `g6e` instances (L40S) are operational using `kubectl describe node`, showing `Allocatable: nvidia.com/gpu: 1`.
