# k8s code resources created mainly for git@github.com:AckeeCZ/goproxie.git compatibility

resource "kubernetes_stateful_set" "elasticsearch" {
  metadata {

    labels = {
      app = "elasticsearch"
    }

    namespace = var.namespace
    name      = "elasticsearch${local.suffix}"
  }

  spec {
    selector {
      match_labels = {
        external-app = "elasticsearch${local.suffix}"
      }
    }

    service_name = "elasticsearch${local.suffix}"

    template {
      metadata {
        labels = {
          external-app = "elasticsearch${local.suffix}"
        }
      }

      spec {
        container {
          name              = "elasticsearch${local.suffix}"
          image             = "alpine/socat"
          image_pull_policy = "IfNotPresent"

          args = [
            "tcp-listen:9200,fork,reuseaddr",
            "tcp-connect:es-ilb.${google_compute_forwarding_rule.elasticsearch.name}.il4.${var.region}.lb.${var.project}.internal:9200",
          ]
          port {
            protocol       = "TCP"
            container_port = 9200
            host_port      = 9200
          }
          resources {
            limits {
              cpu    = "100m"
              memory = "100Mi"
            }
            requests {
              cpu    = "10m"
              memory = "10Mi"
            }
          }
        }
        termination_grace_period_seconds = 1
      }
    }
    update_strategy {
      type = "RollingUpdate"
      rolling_update {
        partition = 0
      }
    }
  }
}


resource "kubernetes_cron_job" "backup_cleanup" {
  metadata {
    name = "elasticsearch-backup"
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    schedule                      = "0 3 * * *"
    successful_jobs_history_limit = 3
    job_template {
      metadata {}
      spec {
        backoff_limit              = 2
        ttl_seconds_after_finished = 10
        template {
          metadata {}
          spec {
            container {
              name    = "elasticsearch-backup-cleanup"
              image   = "curlimages/curl"
              command = ["/bin/sh", "-c", "curl -s -XPOST http://es-ilb.${google_compute_forwarding_rule.elasticsearch.name}.il4.${var.region}.lb.${var.project}.internal:9200/_snapshot/${local.backup_repository}/_cleanup?pretty"]
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}
