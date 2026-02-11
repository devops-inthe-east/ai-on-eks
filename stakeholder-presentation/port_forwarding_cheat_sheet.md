# Port Forwarding Cheat Sheet: Accessing AIBrix Services

Use these commands to access the deployed services from your local machine (localhost). Run each command in a separate terminal.

## 1. DeepSeek LLM (API)
Access the vLLM OpenAI-compatible API endpoint directly.
*   **Command**:
    ```powershell
    kubectl port-forward svc/deepseek-r1-distill-llama-8b 8000:8000 -n deepseek-aibrix
    ```
*   **URL**: `http://localhost:8000/v1/models`
*   **Purpose**: Testing API calls via `curl`, `python`, or `insomnia`.

## 2. Open WebUI (Chat Interface)
The graphical chat interface for interacting with the model.
*   **Command**:
    ```powershell
    kubectl port-forward svc/open-webui 8080:80 -n deepseek-aibrix
    ```
*   **URL**: `http://localhost:8080`
*   **Purpose**: Chatting with the LLM via browser.

## 3. Grafana (Dashboards)
Visualize metrics (Throughput, Latency, GPU Usage).
*   **Command**:
    ```powershell
    kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
    ```
*   **URL**: `http://localhost:3000`
*   **Login**: Default is `admin` / `prom-operator`.

## 4. Prometheus (Raw Metrics)
Inspect raw metric data and targets.
*   **Command**:
    ```powershell
    kubectl port-forward svc/prometheus-operated 9090:9090 -n monitoring
    ```
*   **URL**: `http://localhost:9090`
*   **Purpose**: Debugging scraping issues or checking targets.

## 5. NVIDIA DCGM Logs (GPU Monitoring)
Stream real-time GPU hardware metrics from the exporter pod.
*   **List Pod**:
    ```powershell
    kubectl get pods -n monitoring -l app.kubernetes.io/name=dcgm-exporter
    ```
*   **View Logs**:
    ```powershell
    # Replace <pod-name> with the name from the previous command
    kubectl logs -f <pod-name> -n monitoring
    ```
*   **Verify Metrics (via CLI)**:
    ```powershell
    kubectl port-forward svc/dcgm-exporter 9400:9400 -n monitoring
    # Then run in browser or curl: http://localhost:9400/metrics
    ```
