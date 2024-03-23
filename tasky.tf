resource "kubernetes_deployment" "tasky" {
  depends_on = [kubectl_manifest.tasky_sa,random_pet.mongodbpw]
  metadata {
    name = "tasky"
    namespace = "tasky"
    labels = {
      app = "tasky"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "tasky"
      }
    }
    template {
      metadata {
        labels = {
          app = "tasky"
        }
      }
      spec {
        container {
          image = "lderjim/jpecora-tasky:latest"
          name  = "tasky"
          env {
            name = "MONGODB_URI"
            value = "mongodb://admin:${random_pet.mongodbpw.id}@10.0.4.100:27017"
          }
          env {
            name = "SECRET_KEY"
            value = "Train-Highway-8"
          }
        }
      }
    }
  }
}

resource "kubectl_manifest" "tasky_service" {
  depends_on = [kubernetes_deployment.tasky]
  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: tasky-service-loadbalancer
  namespace: tasky
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
spec:
  type: LoadBalancer
  selector:
    app: tasky
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
YAML
}

resource "kubectl_manifest" "tasky_ns" {
  #depends_on = [helm_release.eks_alb]
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: tasky
YAML
}

resource "kubectl_manifest" "tasky_sa" {
  #depends_on = [helm_release.eks_alb,kubectl_manifest.tasky_ns]
  depends_on = [kubectl_manifest.tasky_ns]
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tasky
  namespace: tasky
YAML
}

resource "kubectl_manifest" "tasky_rb" {
  #depends_on = [helm_release.eks_alb]
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  creationTimestamp: null
  name: tasky-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: tasky
  namespace: tasky
YAML
}
