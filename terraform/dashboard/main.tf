# Proyecto de monitoreo central
provider "google" {
  project = var.monitoring_project_id
  region  = var.monitoring_region
}

# ============================================
# NOTIFICATION CHANNELS (para alertas)
# ============================================

# Canal de notificación por Email
resource "google_monitoring_notification_channel" "email" {
  count           = var.notification_emails != null ? 1 : 0
  display_name    = "Email Notifications"
  type            = "email"
  enabled         = true
  force_delete    = true

  labels = {
    email_address = var.notification_emails[0]
  }
}

# Canal de notificación por Slack
resource "google_monitoring_notification_channel" "slack" {
  count           = var.slack_webhook_url != null ? 1 : 0
  display_name    = "Slack Notifications"
  type            = "slack"
  enabled         = true
  force_delete    = true

  labels = {
    channel_name = var.slack_channel_name
  }

  sensitive_labels {
    auth_token = var.slack_webhook_url
  }
}

# ============================================
# DASHBOARD PRINCIPAL
# ============================================

resource "google_monitoring_dashboard" "gke_cluster" {
  dashboard_json = jsonencode({
    displayName = "GKE Cluster - ${var.cluster_name} (${var.target_project_id})"
    mosaicLayout = {
      columns = 12
      tiles = [
        # ==== Row 1: Estado General ====
        {
          width  = 4
          height = 3
          widget = {
            title = "Node Status"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_cluster\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/container/uptime\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 4
          width  = 4
          height = 3
          widget = {
            title = "Pod Count"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_pod\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/pod/volume/utilization\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 8
          width  = 4
          height = 3
          widget = {
            title = "Container Restarts"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/container/restart_count\""
                  }
                }
              }]
            }
          }
        },
        # ==== Row 2: CPU ====
        {
          yPos   = 3
          width  = 4
          height = 3
          widget = {
            title = "Node CPU Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_node\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/node/cpu/core_usage_time\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 4
          yPos   = 3
          width  = 4
          height = 3
          widget = {
            title = "Pod CPU Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_pod\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/pod/cpu/core_usage_time\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 8
          yPos   = 3
          width  = 4
          height = 3
          widget = {
            title = "Container CPU Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/container/cpu/core_usage_time\""
                  }
                }
              }]
            }
          }
        },
        # ==== Row 3: Memoria ====
        {
          yPos   = 6
          width  = 4
          height = 3
          widget = {
            title = "Node Memory Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_node\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/node/memory/allocatable_bytes\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 4
          yPos   = 6
          width  = 4
          height = 3
          widget = {
            title = "Pod Memory Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_pod\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/pod/memory/working_set_bytes\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 8
          yPos   = 6
          width  = 4
          height = 3
          widget = {
            title = "Container Memory Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/container/memory/working_set_bytes\""
                  }
                }
              }]
            }
          }
        },
        # ==== Row 4: Red ====
        {
          yPos   = 9
          width  = 4
          height = 3
          widget = {
            title = "Pod Network In"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_pod\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/pod/network/received_bytes_count\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 4
          yPos   = 9
          width  = 4
          height = 3
          widget = {
            title = "Pod Network Out"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_pod\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/pod/network/sent_bytes_count\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 8
          yPos   = 9
          width  = 4
          height = 3
          widget = {
            title = "Pod Network Errors"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_pod\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/pod/network/errors_total\""
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}

# ============================================
# ALERT POLICIES
# ============================================

# Alerta: CPU alta en nodos
resource "google_monitoring_alert_policy" "high_node_cpu" {
  count           = var.enable_alerts ? 1 : 0
  display_name    = "High Node CPU Usage"
  combiner        = "OR"
  enabled         = true

  conditions {
    display_name = "CPU > 80%"
    condition_threshold {
      filter          = "resource.type=\"k8s_node\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/node/cpu/allocatable_cores\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period  = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = concat(
    try([google_monitoring_notification_channel.email[0].id], []),
    try([google_monitoring_notification_channel.slack[0].id], [])
  )
}

# Alerta: Memoria alta en nodos
resource "google_monitoring_alert_policy" "high_node_memory" {
  count           = var.enable_alerts ? 1 : 0
  display_name    = "High Node Memory Usage"
  combiner        = "OR"
  enabled         = true

  conditions {
    display_name = "Memory > 85%"
    condition_threshold {
      filter          = "resource.type=\"k8s_node\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/node/memory/allocatable_bytes\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85

      aggregations {
        alignment_period  = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = concat(
    try([google_monitoring_notification_channel.email[0].id], []),
    try([google_monitoring_notification_channel.slack[0].id], [])
  )
}

# Alerta: Pods reinicios frecuentes
resource "google_monitoring_alert_policy" "pod_restarts" {
  count           = var.enable_alerts ? 1 : 0
  display_name    = "High Pod Restart Rate"
  combiner        = "OR"
  enabled         = true

  conditions {
    display_name = "Restarts > 5 in 10min"
    condition_threshold {
      filter          = "resource.type=\"k8s_pod\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/pod/container/restart_count\""
      duration        = "600s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5

      aggregations {
        alignment_period  = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = concat(
    try([google_monitoring_notification_channel.email[0].id], []),
    try([google_monitoring_notification_channel.slack[0].id], [])
  )
}

# Alerta: Pods en estado fallido
resource "google_monitoring_alert_policy" "pod_failures" {
  count           = var.enable_alerts ? 1 : 0
  display_name    = "Pod Failures Detected"
  combiner        = "OR"
  enabled         = true

  conditions {
    display_name = "Failed Pods > 0"
    condition_threshold {
      filter          = "resource.type=\"k8s_pod\" resource.label.project_id=\"${var.target_project_id}\" metadata.system_labels.pod_name=~\".*\" metric.type=\"kubernetes.io/pod/volume/utilization\""
      duration        = "180s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period  = "60s"
        per_series_aligner = "ALIGN_COUNT"
      }
    }
  }

  notification_channels = concat(
    try([google_monitoring_notification_channel.email[0].id], []),
    try([google_monitoring_notification_channel.slack[0].id], [])
  )
}
