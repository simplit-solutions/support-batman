output "monitoring_project_id" {
  value       = var.monitoring_project_id
  description = "Proyecto GCP de monitoreo central"
}

output "dashboard_type" {
  value       = var.dashboard_type
  description = "Tipo de dashboard desplegado (kubernetes o database)"
}

output "kubernetes_dashboard_id" {
  value       = try(google_monitoring_dashboard.gke_cluster[0].id, null)
  description = "ID del dashboard de Kubernetes (si fue desplegado)"
}

output "database_dashboard_id" {
  value       = try(google_monitoring_dashboard.cloud_sql[0].id, null)
  description = "ID del dashboard de Cloud SQL (si fue desplegado)"
}

output "alert_policies_kubernetes" {
  value = {
    high_node_cpu    = try(google_monitoring_alert_policy.high_node_cpu[0].id, null)
    high_node_memory = try(google_monitoring_alert_policy.high_node_memory[0].id, null)
    pod_restarts     = try(google_monitoring_alert_policy.pod_restarts[0].id, null)
    node_not_ready   = try(google_monitoring_alert_policy.node_not_ready[0].id, null)
  }
  description = "IDs de alertas de Kubernetes"
}

output "alert_policies_database" {
  value = {
    high_db_cpu    = try(google_monitoring_alert_policy.high_db_cpu[0].id, null)
    high_db_memory = try(google_monitoring_alert_policy.high_db_memory[0].id, null)
    high_db_disk   = try(google_monitoring_alert_policy.high_db_disk[0].id, null)
  }
  description = "IDs de alertas de Database"
}

output "notification_channels" {
  value = {
    email = [for _, c in google_monitoring_notification_channel.email : c.id]
    slack = try(google_monitoring_notification_channel.slack[0].id, null)
  }
  description = "Canales de notificación creados"
}

output "gcp_console_url" {
  value       = "https://console.cloud.google.com/monitoring/dashboards?project=${var.monitoring_project_id}"
  description = "URL directa al dashboard en GCP Console"
}
