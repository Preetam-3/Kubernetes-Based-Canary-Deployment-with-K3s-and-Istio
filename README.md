# Canary Deployment with K3s, Istio and Helm

A hands-on canary release on a local Kubernetes cluster. Two versions of a small Node.js app run side by side, and Istio splits traffic between them. A single Helm chart moves the split through each stage (80/20, 50/50, full promotion, rollback) with one command per stage.

## Architecture

```
curl / browser
      |
istio-ingressgateway
      |
  Gateway -> VirtualService (weighted routes)
                  |
           DestinationRule (subsets)
              /        \
   hello-node v1    hello-node v2
```

| Component | Role |
|---|---|
| K3s | Lightweight single-node Kubernetes |
| Istio | Ingress gateway and weighted traffic splitting |
| Helm | Packages the app and Istio resources, switches stages via values files |
| Docker | Builds the v1 and v2 images |
| Kiali, Prometheus, Grafana | Traffic visualisation and metrics |

## Repository layout

```
app/                 Node.js source and Dockerfile for v1 and v2
helm/hello-node-canary/
  Chart.yaml
  values.yaml        Default values (80/20)
  values-80-20.yaml
  values-50-50.yaml
  values-promote.yaml    0/100 (all traffic to v2)
  values-rollback.yaml   100/0 (all traffic to v1)
  templates/         Deployments, Service, Gateway, DestinationRule, VirtualService
scripts/traffic-test.sh  Counts responses per version
monitoring/          Observability notes
docs/                Screenshots and the original manual manifests
```

## Prerequisites

- K3s running, with `kubectl` pointed at it
- Istio installed (`istioctl`) with the ingress gateway running
- Helm 3 and Docker

## Setup

**1. Create the namespace with sidecar injection**

```bash
kubectl create namespace demo
kubectl label namespace demo istio-injection=enabled
```

**2. Build the images and import them into K3s**

```bash
docker build -t hello-node:v1 app/node-hello-v1
docker build -t hello-node:v2 app/node-hello-v2

docker save hello-node:v1 | sudo k3s ctr images import -
docker save hello-node:v2 | sudo k3s ctr images import -
```

**3. Install the chart at 80/20**

```bash
helm install hello-node helm/hello-node-canary -n demo \
  -f helm/hello-node-canary/values-80-20.yaml
```

**4. Verify**

```bash
kubectl get pods,svc -n demo
kubectl get virtualservices,destinationrules,gateways.networking.istio.io -n demo
```

Both `hello-node` pods should show `2/2 Running` (app plus Istio sidecar).

## Running the canary

Move through the stages with `helm upgrade`, testing after each one:

```bash
helm upgrade hello-node helm/hello-node-canary -n demo -f helm/hello-node-canary/values-50-50.yaml
helm upgrade hello-node helm/hello-node-canary -n demo -f helm/hello-node-canary/values-promote.yaml
helm upgrade hello-node helm/hello-node-canary -n demo -f helm/hello-node-canary/values-rollback.yaml
```

| Values file | v1 | v2 |
|---|---|---|
| `values-80-20.yaml` | 80% | 20% |
| `values-50-50.yaml` | 50% | 50% |
| `values-promote.yaml` | 0% | 100% |
| `values-rollback.yaml` | 100% | 0% |

## Testing the traffic split

```bash
bash scripts/traffic-test.sh 100
```

The script sends 100 requests through the ingress gateway and prints how many responses each version served. v1 answers `Hello Node!` and v2 answers `Hello Node!_v2`.

Example at 50/50:

```
  51 requests ( 51%)  Hello Node!
  49 requests ( 49%)  Hello Node!_v2
```

## Observability

See [monitoring/README.md](monitoring/README.md) for opening Kiali, Grafana and Prometheus.

## Cleanup

```bash
helm uninstall hello-node -n demo
```

## Notes

- The images are not stored in the repository. Build them as shown in the setup steps.
- The original hand-written manifests live in `docs/manual-manifests/` for reference. Do not apply them alongside the Helm release, because both manage the same resources.
