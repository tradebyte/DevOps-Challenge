resource "kubernetes_service_v1" "redis" {
  metadata {
    name      = var.redis_name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    selector = {
      app = var.redis_name
    }
    port {
      port        = var.redis_port
      target_port = var.redis_port
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_persistent_volume_claim_v1" "redis" {
  wait_until_bound = false

  metadata {
    name      = "${var.redis_name}-data"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-path"
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_deployment_v1" "redis" {
  metadata {
    name      = var.redis_name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels = {
      app = var.redis_name
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = var.redis_name
      }
    }
    template {
      metadata {
        labels = {
          app = var.redis_name
        }
      }
      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 999
          fs_group        = 999
        }
        container {
          name    = "redis"
          image   = "redis:7-alpine"
          command = ["redis-server", "--appendonly", "yes"]

          port {
            container_port = var.redis_port
          }
          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
          readiness_probe {
            exec {
              command = ["redis-cli", "ping"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
          liveness_probe {
            exec {
              command = ["redis-cli", "ping"]
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.redis.metadata[0].name
          }
        }
      }
    }
  }
  
}
