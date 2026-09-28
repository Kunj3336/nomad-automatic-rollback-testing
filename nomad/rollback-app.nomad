job "rollback-app" {
  datacenters = ["dc1"]
  type        = "service"

  update {
    max_parallel      = 2
    min_healthy_time  = "5s"
    healthy_deadline  = "30s"
    progress_deadline = "1m"
    auto_revert       = true
  }

  group "web" {
    count = 5

    restart {
      attempts = 2
      interval = "30s"
      delay    = "5s"
      mode     = "fail"
    }

    network {
      port "http" {
        to = 8080
      }
    }

    service {
      name = "rollback-service"
      port = "http"

      check {
        type     = "http"
        path     = "/health"
        interval = "3s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "docker"

      config {
        image = "rollback-app:v1"
        ports = ["http"]
      }

      env {
        APP_VERSION   = "v2-partial-fail"
        HEALTH_STATUS = "503"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}