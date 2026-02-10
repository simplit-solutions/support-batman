# ============================================
# Proyecto de monitoreo central
# ============================================

provider "google" {
  project = var.monitoring_project_id
  region  = var.monitoring_region
}

locals {
  # Namespace filtering (exact list)
  namespace_filter_expr = var.namespace_filter == "exact" && length(var.namespace_list) > 0 ? (
    " (" + join(" OR ", [for ns in var.namespace_list : format("resource.label.namespace_name=\"%s\"", ns)]) + ")"
  ) : ""

  # Namespace grouping (qa2, qa3, etc.)
  namespace_group_expr = {
    for k, v in var.namespace_groups :
    k => (length(v) > 0 ? (" (" + join(" OR ", [for ns in v : format("resource.label.namespace_name=\"%s\"", ns)]) + ")") : "")
  }

  # Slack token: prefer OAuth token, fallback to legacy field if needed
  slack_token = coalesce(var.slack_auth_token, var.slack_webhook_url)

  # Notification channel IDs for alert policies
  notification_channel_ids = concat(
    [for _, c in google_monitoring_notification_channel.email : c.id],
    try([google_monitoring_notification_channel.slack[0].id], [])
  )
}

# ============================================
# NOTIFICATION CHANNELS
# ============================================

# Email notification channels (one per email address)
resource "google_monitoring_notification_channel" "email" {
  for_each      = toset(var.notification_emails)
  display_name  = "Email - ${each.value}"
  type          = "email"
  labels = {
    email_address = each.value
  }
}

# Slack notification channel (optional, only if auth_token provided)
resource "google_monitoring_notification_channel" "slack" {
  count         = local.slack_token != null ? 1 : 0
  display_name  = "Slack - ${var.slack_channel_name}"
  type          = "slack"
  labels = {
    channel_name = var.slack_channel_name
  }
  sensitive_labels {
    auth_token = local.slack_token
  }
}

# ============================================
# KUBERNETES DASHBOARD
# ============================================

resource "google_monitoring_dashboard" "gke_cluster" {
  count          = var.dashboard_type == "kubernetes" ? 1 : 0
  dashboard_json = jsonencode({
    displayName = "GKE Cluster - ${var.cluster_name} (${var.target_project_id})"
    mosaicLayout = {
      columns = 12
      tiles = [
        # ==== Row 1: Instance Group Size ====
        {
          width  = 12
          height = 3
          widget = {
            title = "Instance group size [MAX]"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/container/uptime\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MAX"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Size"
                scale = "LINEAR"
              }
            }
          }
        },

        # ==== Row 2: CPU/Memory Limit Utilization QA1 ====
        {
          yPos   = 3
          width  = 6
          height = 3
          widget = {
            title = "K - CPU limit utilization QA1"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\"${local.namespace_filter_expr} metric.type=\"kubernetes.io/container/cpu/limit_utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 3
          width  = 6
          height = 3
          widget = {
            title = "K - Memory limit utilization for qa1"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\"${local.namespace_filter_expr} metric.type=\"kubernetes.io/container/memory/limit_utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },

        # ==== Row 3: CPU/Memory Limit QA2 ====
        {
          yPos   = 6
          width  = 6
          height = 3
          widget = {
            title = "K - CPU limit utilization QA 2"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\"${lookup(local.namespace_group_expr, "qa2", "")} metric.type=\"kubernetes.io/container/cpu/limit_utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 6
          width  = 6
          height = 3
          widget = {
            title = "K - Memory limit utilization for qa2"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\"${lookup(local.namespace_group_expr, "qa2", "")} metric.type=\"kubernetes.io/container/memory/limit_utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },

        # ==== Row 4: Gauges QA2 ====
        {
          yPos   = 9
          width  = 6
          height = 3
          widget = {
            title = "Kubernetes Container - CPU limit utilization for qa2, icarus-api [MAX]"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\" resource.label.namespace_name=\"qa2\" resource.label.container_name=\"icarus-api\" metric.type=\"kubernetes.io/container/cpu/limit_utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MAX"
                    }
                  }
                }
              }]
              yAxis = {
                label = "Value"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          xPos   = 6
          yPos   = 9
          width  = 6
          height = 3
          widget = {
            title = "Kubernetes Container - Memory limit utilization for icarus-api, qa2 [MAX]"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\" resource.label.namespace_name=\"qa2\" resource.label.container_name=\"icarus-api\" metric.type=\"kubernetes.io/container/memory/limit_utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MAX"
                    }
                  }
                }
              }]
              yAxis = {
                label = "Value"
                scale = "LINEAR"
              }
            }
          }
        },

        # ==== Row 5: HPA QA2 ====
        {
          yPos   = 12
          width  = 12
          height = 3
          widget = {
            title = "Kubernetes HPA QA2"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\" resource.label.namespace_name=\"qa2\" metric.type=\"kubernetes.io/container/uptime\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
              }]
            }
          }
        },

        # ==== Row 6: CPU/Memory Limit QA3 ====
        {
          yPos   = 15
          width  = 6
          height = 3
          widget = {
            title = "K - CPU limit utilization QA 3"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\"${lookup(local.namespace_group_expr, "qa3", "")} metric.type=\"kubernetes.io/container/cpu/limit_utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 15
          width  = 6
          height = 3
          widget = {
            title = "K - Memory limit utilization for qa3"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\"${lookup(local.namespace_group_expr, "qa3", "")} metric.type=\"kubernetes.io/container/memory/limit_utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
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
# ALERT POLICIES - Kubernetes
# ============================================

# Alerta: CPU alta en nodos (utilización sobre allocatable)
resource "google_monitoring_alert_policy" "high_node_cpu" {
  count        = var.enable_alerts && var.dashboard_type == "kubernetes" ? 1 : 0
  display_name = "High Node CPU Usage"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "CPU allocatable utilization > 80% (5m)"
    condition_threshold {
      filter          = "resource.type=\"k8s_node\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/node/cpu/allocatable_utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = local.notification_channel_ids
}

# Alerta: Memoria alta en nodos (utilización sobre allocatable)
resource "google_monitoring_alert_policy" "high_node_memory" {
  count        = var.enable_alerts && var.dashboard_type == "kubernetes" ? 1 : 0
  display_name = "High Node Memory Usage"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Memory allocatable utilization > 85% (5m)"
    condition_threshold {
      filter          = "resource.type=\"k8s_node\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/node/memory/allocatable_utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = local.notification_channel_ids
}

# Alerta: Reinicios de contenedores (delta en 10m)
resource "google_monitoring_alert_policy" "pod_restarts" {
  count        = var.enable_alerts && var.dashboard_type == "kubernetes" ? 1 : 0
  display_name = "High Container Restart Count (10m)"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Restarts > 5 in 10m"
    condition_threshold {
      filter          = "resource.type=\"k8s_pod\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/pod/container/restart_count\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5

      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_DELTA"
      }
    }
  }

  notification_channels = local.notification_channel_ids
}

# Alerta: Nodo no listo (Ready = False/Unknown)
resource "google_monitoring_alert_policy" "node_not_ready" {
  count        = var.enable_alerts && var.dashboard_type == "kubernetes" ? 1 : 0
  display_name = "Node Not Ready"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Ready=False (5m)"
    condition_threshold {
      filter          = "resource.type=\"k8s_node\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/node/status_condition\" metric.label.condition=\"Ready\" metric.label.status=\"False\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  conditions {
    display_name = "Ready=Unknown (5m)"
    condition_threshold {
      filter          = "resource.type=\"k8s_node\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/node/status_condition\" metric.label.condition=\"Ready\" metric.label.status=\"Unknown\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = local.notification_channel_ids
}

# ============================================
# DATABASE DASHBOARD
# ============================================

resource "google_monitoring_dashboard" "cloud_sql" {
  count          = var.dashboard_type == "database" ? 1 : 0
  dashboard_json = jsonencode({
    displayName = "Cloud SQL - ${var.database_instance} (${var.database_project_id})"
    mosaicLayout = {
      columns = 12
      tiles = [
        # ==== Row 1: CPU Utilization ====
        {
          width  = 6
          height = 3
          widget = {
            title = "Cloud SQL Database - CPU utilization [MEAN]"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.database_id=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          width  = 6
          height = 3
          widget = {
            title = "Uso de CPU BD escritura"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.database_id=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/disk/write_ops_count\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
              }]
            }
          }
        },

        # ==== Row 2: Memory ====
        {
          yPos   = 3
          width  = 6
          height = 3
          widget = {
            title = "Uso total de memoria"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.database_id=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/memory/utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
              yAxis = {
                label = "Memory (MB)"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          xPos   = 6
          yPos   = 3
          width  = 6
          height = 3
          widget = {
            title = "Uso de CPU"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.database_id=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
              yAxis = {
                label = "CPU %"
                scale = "LINEAR"
              }
            }
          }
        },

        # ==== Row 3: CPU Seconds ====
        {
          yPos   = 6
          width  = 6
          height = 3
          widget = {
            title = "Segundos de CPU"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.database_id=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/mysql/queries\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 6
          width  = 6
          height = 3
          widget = {
            title = "Connections"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.database_id=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/network/connections\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },

        # ==== Row 4: Database Calls ====
        {
          yPos   = 9
          width  = 12
          height = 3
          widget = {
            title = "Llamadas"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.database_id=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/mysql/queries\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_NONE"
                    }
                  }
                }
              }]
              yAxis = {
                label = "Queries/sec"
                scale = "LINEAR"
              }
            }
          }
        },

        # ==== Row 5: Disk Utilization ====
        {
          yPos   = 12
          width  = 6
          height = 3
          widget = {
            title = "Disk Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.database_id=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/disk/utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 12
          width  = 6
          height = 3
          widget = {
            title = "Database Instance Up"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.database_id=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/up\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
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
# ALERT POLICIES - Database
# ============================================

# Alerta: CPU alta en database
resource "google_monitoring_alert_policy" "high_db_cpu" {
  count        = var.enable_alerts && var.dashboard_type == "database" ? 1 : 0
  display_name = "High Database CPU Usage"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "CPU > 80%"
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.database_id=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = local.notification_channel_ids
}

# Alerta: Memoria alta en database
resource "google_monitoring_alert_policy" "high_db_memory" {
  count        = var.enable_alerts && var.dashboard_type == "database" ? 1 : 0
  display_name = "High Database Memory Usage"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Memory > 85%"
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.database_id=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/memory/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = local.notification_channel_ids
}

# Alerta: Disco lleno en database
resource "google_monitoring_alert_policy" "high_db_disk" {
  count        = var.enable_alerts && var.dashboard_type == "database" ? 1 : 0
  display_name = "High Database Disk Usage"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Disk > 90%"
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.database_id=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/disk/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.9

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = local.notification_channel_ids
}
