resource "kubernetes_service_account_v1" "vault_injector" {
  metadata {
    name      = "vault-agent-injector"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
}

resource "kubernetes_cluster_role_v1" "vault_injector" {
  metadata {
    name = "vault-agent-injector-${kubernetes_namespace_v1.this.metadata[0].name}"
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "secrets"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["admissionregistration.k8s.io"]
    resources  = ["mutatingwebhookconfigurations"]
    verbs      = ["get", "list", "watch", "update", "patch"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "vault_injector" {
  metadata {
    name = "vault-agent-injector-${kubernetes_namespace_v1.this.metadata[0].name}"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.vault_injector.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.vault_injector.metadata[0].name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
}

resource "kubernetes_deployment_v1" "vault_injector" {
  metadata {
    name      = "vault-agent-injector"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "vault-agent-injector"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "vault-agent-injector"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "vault-agent-injector"
        }
      }
      spec {
        service_account_name = kubernetes_service_account_v1.vault_injector.metadata[0].name
        container {
          name  = "sidecar-injector"
          image = "hashicorp/vault-k8s:1.4.2"
          args  = ["agent-inject"]

          env {
            name = "NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          env {
            name  = "AGENT_INJECT_LISTEN"
            value = ":8080"
          }
          env {
            name  = "AGENT_INJECT_VAULT_ADDR"
            value = "http://vault.${kubernetes_namespace_v1.this.metadata[0].name}.svc:8200"
          }
          env {
            name  = "AGENT_INJECT_VAULT_IMAGE"
            value = "hashicorp/vault:1.15"
          }
          env {
            name  = "AGENT_INJECT_TLS_AUTO"
            value = "vault-agent-injector-cfg"
          }
          env {
            name  = "AGENT_INJECT_USE_LEADER_ELECTOR"
            value = "false"
          }

          port {
            container_port = 8080
          }
          resources {
            requests = {
              cpu    = "250m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "128Mi"
            }
          }
          readiness_probe {
            http_get {
              path   = "/health/ready"
              port   = 8080
              scheme = "HTTPS"
            }
            initial_delay_seconds = 5
            period_seconds        = 2
            failure_threshold     = 2
          }
          liveness_probe {
            http_get {
              path   = "/health/ready"
              port   = 8080
              scheme = "HTTPS"
            }
            initial_delay_seconds = 5
            period_seconds         = 2
            failure_threshold      = 2
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "vault_injector" {
  metadata {
    name      = "vault-agent-injector-svc"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "vault-agent-injector"
    }
    port {
      port        = 443
      target_port = 8080
    }
  }
}

resource "kubernetes_mutating_webhook_configuration_v1" "vault_injector" {
  metadata {
    name = "vault-agent-injector-cfg"
  }
  webhook {
    name                      = "vault.hashicorp.com"
    admission_review_versions = ["v1"]
    side_effects              = "None"
    failure_policy            = "Ignore"

    client_config {
      service {
        name      = kubernetes_service_v1.vault_injector.metadata[0].name
        namespace = kubernetes_namespace_v1.this.metadata[0].name
        path      = "/mutate"
      }
      ca_bundle = ""
    }

    rule {
      operations   = ["CREATE"]
      api_groups   = [""]
      api_versions = ["v1"]
      resources    = ["pods"]
      scope        = "Namespaced"
    }

    object_selector {
      match_expressions {
        key      = "app.kubernetes.io/name"
        operator = "NotIn"
        values   = ["vault-agent-injector"]
      }
    }
  }
}