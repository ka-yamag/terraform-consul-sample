resource "kubernetes_stateful_set" "consul" {
  metadata {
    name = "consul"
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "consul"

        component = "server"
      }
    }

    template {
      metadata {
        labels = {
          app       = "consul"
          component = "server"
        }
        annotations = {
          "consul.hashicorp.com/connect-inject" = "false"
        }
      }

      spec {
        volume {
          name = "config"
          config_map {
            name = "consul"
          }
        }

        volume {
          name = "tls"

          secret {
            secret_name = "consul"
          }
        }

        container {
          name  = "consul"
          image = "consul:1.4.0-rc1"
          args = [
            "agent",
            "-advertise=$(POD_IP)",
            "-bootstrap-expect=3",
            "-config-file=/etc/consul/config/server.json",
            "-encrypt=$(GOSSIP_ENCRYPTION_KEY)"
          ]

          port {
            name           = "ui-port"
            container_port = 8500
          }

          port {
            name           = "alt-port"
            container_port = 8400
          }

          port {
            name           = "udp-port"
            container_port = 53
          }

          port {
            name           = "https-port"
            container_port = 8443
          }

          port {
            name           = "http-port"
            container_port = 8080
          }

          port {
            name           = "serflan"
            container_port = 8301
          }

          port {
            name           = "serfwan"
            container_port = 8302
          }

          port {
            name           = "consuldns"
            container_port = 8600
          }

          port {
            name           = "server"
            container_port = 8300
          }

          env {
            name = "POD_IP"

            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          env {
            name = "GOSSIP_ENCRYPTION_KEY"

            value_from {
              secret_key_ref {
                name = "consul"
                key  = "gossip-encryption-key"
              }
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/consul/data"
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/consul/config"
          }

          volume_mount {
            name       = "tls"
            mount_path = "/etc/tls"
          }

          lifecycle {
            pre_stop {
              exec {
                command = ["/bin/sh", "-c", "consul leave"]
              }
            }
          }
        }

        termination_grace_period_seconds = 10
        service_account_name             = "consul"

        security_context {
          fs_group = 1000
        }

        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {}

              topology_key = "kubernetes.io/hostname"
            }
          }
        }
      }
    }

    service_name          = "consul"
    pod_management_policy = "Parallel"
  }
}
