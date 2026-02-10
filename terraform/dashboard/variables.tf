variable "monitoring_project_id" {
  type        = string
  description = "ID del proyecto GCP donde se crearán los dashboards y alertas (proyecto central de monitoreo)"
}

variable "monitoring_region" {
  type        = string
  description = "Región del proyecto de monitoreo"
  default     = "us-central1"
}

variable "target_project_id" {
  type        = string
  description = "ID del proyecto GCP que contiene el clúster GKE a monitorear"
}

variable "cluster_name" {
  type        = string
  description = "Nombre del clúster GKE a monitorear"
}

variable "enable_alerts" {
  type        = bool
  description = "Habilitar creación de alertas"
  default     = true
}

variable "notification_emails" {
  type        = list(string)
  description = "Lista de emails para recibir notificaciones de alertas"
  default     = null
}

variable "slack_webhook_url" {
  type        = string
  sensitive   = true
  description = "URL del webhook de Slack para notificaciones (obtener de Slack app)"
  default     = null
}

variable "slack_channel_name" {
  type        = string
  description = "Nombre del canal Slack para notificaciones"
  default     = "#alerts"
}
