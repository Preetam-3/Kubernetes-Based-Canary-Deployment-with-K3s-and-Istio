# Monitoring

Observability for the canary runs on Istio's standard addons in the `istio-system` namespace:

| Tool | Purpose | Port |
|---|---|---|
| Kiali | Live service graph with traffic percentages | 20001 |
| Grafana | Dashboards | 3000 |
| Prometheus | Metrics store and queries | 9090 |

## Access

Run each port-forward in its own terminal:

```bash
kubectl port-forward -n istio-system svc/kiali 20001:20001
kubectl port-forward -n istio-system svc/grafana 3000:3000
kubectl port-forward -n istio-system svc/prometheus 9090:9090
```

Then open `http://localhost:20001`, `http://localhost:3000` or `http://localhost:9090`.

## Watching the canary in Kiali

1. Keep steady traffic running in a spare terminal:

   ```bash
   while true; do curl -s http://localhost/ > /dev/null; sleep 0.2; done
   ```

2. In Kiali, open **Graph**, select the `demo` and `istio-system` namespaces, and choose **Versioned app graph**.
3. Under **Display**, enable **Traffic Distribution**. Set the time range to **Last 1m** and refresh to **Every 10s**.
4. Run a `helm upgrade` for the stage you want to observe. Kiali takes up to a minute to catch up.

At 50/50 the edges from `hello-node` show about 50% to v1 and 50% to v2. After promotion only v2 receives traffic, and after rollback only v1.

## Installing the addons

If the addons are missing, install them from the `samples/addons` folder of the Istio release you downloaded:

```bash
kubectl apply -f samples/addons
```
