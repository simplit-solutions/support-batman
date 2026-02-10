# Proyecto de monitoreo central
provider "google" {
  project = var.monitoring_project_id
  region  = var.monitoring_region
}

locals {
  namespace_filter_expr = var.namespace_filter == "exact" && length(var.namespace_list) > 0 ? (" " + "(" + join(" OR ", [for ns in var.namespace_list : format("resource.label.namespace_name=\"%s\"", ns)]) + ")") : ""

  namespace_group_expr = { for k, v in var.namespace_groups : k => (length(v) > 0 ? (" " + "(" + join(" OR ", [for ns in v : format("resource.label.namespace_name=\"%s\"", ns)]) + ")") : "") }
}

# ============================================
# NOTIFICATION CHANNELS (para alertas)
# ============================================

# Canal de notificación por Email
resource "google_monitoring_notification_channel" "email" {
  count           = var.notification_emails != null && length(var.notification_emails) > 0 ? 1 : 0
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
  count           = var.slack_webhook_url != null && length(trimspace(var.slack_webhook_url)) > 0 ? 1 : 0
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
# KUBERNETES DASHBOARD
# ============================================

resource "google_monitoring_dashboard" "gke_cluster" {
  count           = var.dashboard_type == "kubernetes" ? 1 : 0
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
                    filter = "resource.type=\"gke_container\" resource.label.project_id=\"${var.target_project_id}\" metric.type=\"kubernetes.io/container/uptime\""
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
        
        # ==== Row 2: CPU Limit Utilization QA1 ====
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
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\" ${local.namespace_filter_expr} metric.type=\"kubernetes.io/container/cpu/limit_utilization\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
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
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\" ${local.namespace_filter_expr} metric.type=\"kubernetes.io/container/memory/limit_utilization\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
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
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\" ${local.namespace_group_expr[\"qa2\"]} metric.type=\"kubernetes.io/container/cpu/limit_utilization\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
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
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\" ${local.namespace_group_expr[\"qa2\"]} metric.type=\"kubernetes.io/container/memory/limit_utilization\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
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
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MAX"
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
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MAX"
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
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
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
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\" ${local.namespace_group_expr[\"qa3\"]} metric.type=\"kubernetes.io/container/cpu/limit_utilization\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
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
                    filter = "resource.type=\"k8s_container\" resource.label.project_id=\"${var.target_project_id}\" ${local.namespace_group_expr[\"qa3\"]} metric.type=\"kubernetes.io/container/memory/limit_utilization\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
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

# ============================================
# DATABASE DASHBOARD
# ============================================

resource "google_monitoring_dashboard" "cloud_sql" {
  count           = var.dashboard_type == "database" ? 1 : 0
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
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
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
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/disk/write_ops_count\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
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
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/memory/utilization\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
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
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
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
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/mysql/queries\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
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
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/network/connections\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
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
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/mysql/queries\""
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
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/disk/utilization\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
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
                    filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/up\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
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
  count           = var.enable_alerts && var.dashboard_type == "database" ? 1 : 0
  display_name    = "High Database CPU Usage"
  combiner        = "OR"
  enabled         = true

  conditions {
    display_name = "CPU > 80%"
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
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

# Alerta: Memoria alta en database
resource "google_monitoring_alert_policy" "high_db_memory" {
  count           = var.enable_alerts && var.dashboard_type == "database" ? 1 : 0
  display_name    = "High Database Memory Usage"
  combiner        = "OR"
  enabled         = true

  conditions {
    display_name = "Memory > 85%"
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/memory/utilization\""
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

# Alerta: Disco lleno en database
resource "google_monitoring_alert_policy" "high_db_disk" {
  count           = var.enable_alerts && var.dashboard_type == "database" ? 1 : 0
  display_name    = "High Database Disk Usage"
  combiner        = "OR"
  enabled         = true

  conditions {
    display_name = "Disk > 90%"
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.database_project_id}\" resource.label.=\"${var.database_project_id}:${var.database_instance}\" metric.type=\"cloudsql.googleapis.com/database/disk/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.9

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
