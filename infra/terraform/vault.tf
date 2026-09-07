resource "kubernetes_service_v1" "vault" {
  metadata {
    name      = "vault"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    selector = {
      app = "vault"
    }
    port {
      port        = 8200
      target_port = 8200
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_deployment_v1" "vault" {
  metadata {
    name      = "vault"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels = {
      app = "vault"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "vault"
      }
    }
    template {
      metadata {
        labels = {
          app = "vault"
        }
      }
      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 100
          fs_group        = 100
        }
        container {
          name  = "vault"
          image = "hashicorp/vault:1.15"
          args  = ["server", "-dev", "-dev-root-token-id=root", "-dev-listen-address=0.0.0.0:8200"]
          
          # ====== ADDED ENVIRONMENT FLAGS TO SKIP PRIVILEGED OPERATIONS ======
          env {
            name  = "SKIP_CHOWN"
            value = "true"
          }
          env {
            name  = "SKIP_SETCAP"
            value = "true"
          }
          env {
            name  = "VAULT_LOCAL_CONFIG"
            value = "disable_mlock = true"
          }
          # ===================================================================

          port {
            container_port = 8200
          }
          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "128Mi"
            }
          }
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }
          volume_mount {
            name       = "vault-config"
            mount_path = "/vault/config"
          }
          volume_mount {
            name       = "vault-file"
            mount_path = "/vault/file"
          }
        }
        volume {
          name = "vault-config"
          empty_dir {}
        }
        volume {
          name = "vault-file"
          empty_dir {}
        }
      }
    }
  }
}
