# Kubernetes

## Crea un archivo YAML de despliegue de Kubernetes para una aplicación Ruby on Rails.

No tengo experiencia en Kubernetes, he realizado el `ruby_deployment.yaml`, siguiendo la creacion de recursos de la [documentacion oficial de kubernetes](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).
Para su ejecucion en kubernetes cluster, usaremos el siguiente comando:
```
kubctl create -f ruby_deployment.yaml
```