output "monitoring_project_id" {
  value       = var.monitoring_project_id
  description = "Proyecto GCP de monitoreo central"
}

output "target_project_id" {
  value       = var.target_project_id
  description = "Proyecto GCP del clúster monitoreado"
}

output "dashboard_id" {
  value       = google_monitoring_dashboard.gke_cluster.id
  description = "ID del dashboard de GKE"
}

output "dashboard_name" {
  value       = google_monitoring_dashboard.gke_cluster.dashboard_json
  description = "Nombre del dashboard"
}

output "alert_policies" {
  value = {
    high_node_cpu    = try(google_monitoring_alert_policy.high_node_cpu[0].id, null)
    high_node_memory = try(google_monitoring_alert_policy.high_node_memory[0].id, null)
    pod_restarts     = try(google_monitoring_alert_policy.pod_restarts[0].id, null)
    pod_failures     = try(google_monitoring_alert_policy.pod_failures[0].id, null)
  }
  description = "IDs de las políticas de alerta"
}

output "notification_channels" {
  value = {
    email = try(google_monitoring_notification_channel.email[0].id, null)
    slack = try(google_monitoring_notification_channel.slack[0].id, null)
  }
  description = "Canales de notificación creados"
}

output "gcp_console_url" {
  value       = "https://console.cloud.google.com/monitoring/dashboards?project=${var.monitoring_project_id}"
  description = "URL directa al dashboard en GCP Console"
}
