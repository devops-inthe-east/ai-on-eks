# Install KubeRay CRDs v1.2.2 (Matched to Operator Version)
kubectl apply -k "github.com/ray-project/kuberay/ray-operator/config/crd?ref=v1.2.2"

# Restart Control Plane Pods
kubectl delete pod -n aibrix-system -l app.kubernetes.io/instance=aibrix-controller-manager
kubectl delete pod -n aibrix-system -l app.kubernetes.io/name=kuberay-operator