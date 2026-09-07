terraform {
  source = "./terraform"
}

inputs = {
  namespace          = "tradebyte"
  app_name           = "tradebyte-app"
  redis_name         = "redis"
  image              = "tradebyte-app:local"
  replicas           = 3
  min_replicas       = 3
  max_replicas       = 10
  cpu_target_percent = 70
  app_port            = 8888
  environment        = "PROD"
  host               = "0.0.0.0"
  redis_port         = 6379
  redis_db           = 0
  redis_pod_security_context = {
    run_as_user  = 999
    fs_group     = 999
    run_as_non_root = true
  }
  redis_security_context = {
    allow_privilege_escalation = false
    run_as_user                = 999
    run_as_non_root            = true
  }
}
