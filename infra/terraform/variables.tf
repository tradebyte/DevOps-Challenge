variable "namespace" {
  type    = string
  default = "tradebyte"
}

variable "app_name" {
  type    = string
  default = "tradebyte-app"
}

variable "redis_name" {
  type    = string
  default = "redis"
}

variable "image" {
  type = string
}

variable "replicas" {
  type    = number
  default = 3
}

variable "min_replicas" {
  type    = number
  default = 3
}

variable "max_replicas" {
  type    = number
  default = 10
}

variable "cpu_target_percent" {
  type    = number
  default = 70
}

variable "app_port" {
  type    = number
  default = 8888
}

variable "environment" {
  type    = string
  default = "PROD"
}

variable "host" {
  type    = string
  default = "0.0.0.0"
}

variable "redis_port" {
  type    = number
  default = 6379
}

variable "redis_db" {
  type    = number
  default = 0
}

variable "kube_context" {
  type    = string
  default = "minikube"
}
