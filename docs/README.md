# Docs

## Screenshots

Kiali graphs captured at each canary stage live here:

| Stage | File |
|---|---|
| 80/20 | `kiali-80-20.png` |
| 50/50 | `kiali-50-50.png` |
| Promote (100% v2) | `kiali-promote.png` |
| Rollback (100% v1) | `kiali-rollback.png` |

## manual-manifests/

The plain Kubernetes and Istio YAML used before the project moved to Helm:

- `k8s/` has the Service and the v1 and v2 Deployments.
- `istio/` has the Gateway, DestinationRule and one VirtualService per stage.

These are kept for reference and learning only. Do not apply them to a cluster that already has the Helm release installed, because they manage the same resources.
