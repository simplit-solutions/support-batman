variable "dashboard_type" {
  type        = string
  description = "Tipo de dashboard: 'kubernetes' o 'database'"
  validation {
    condition     = contains(["kubernetes", "database"], var.dashboard_type)
    error_message = "dashboard_type debe ser 'kubernetes' o 'database'."
  }
}

variable "monitoring_project_id" {
  type        = string
  description = "ID del proyecto GCP donde se crearán los dashboards y alertas (proyecto central de monitoreo)"
}

variable "monitoring_region" {
  type        = string
  description = "Región del proyecto de monitoreo"
  default     = "us-central1"
}

# ========== Variables para Kubernetes Dashboard ==========
variable "target_project_id" {
  type        = string
  description = "[K8s] ID del proyecto GCP que contiene el clúster GKE a monitorear"
  default     = ""
}

variable "cluster_name" {
  type        = string
  description = "[K8s] Nombre del clúster GKE a monitorear"
  default     = ""
}

# ========== Variables para Database Dashboard ==========
variable "database_project_id" {
  type        = string
  description = "[DB] ID del proyecto GCP que contiene las bases de datos"
  default     = ""
}

variable "database_instance" {
  type        = string
  description = "[DB] Nombre de la instancia de Cloud SQL"
  default     = ""
}

variable "database_name" {
  type        = string
  description = "[DB] Nombre de la base de datos"
  default     = ""
}

# ========== Variables de Alertas ==========
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

# Optional namespace filter: 'none' (default) or 'exact'.
variable "namespace_filter" {
  type        = string
  description = "Modo de filtro por namespace: 'none' (omitir), 'exact' (usar lista namespace_list)"
  default     = "none"
}

variable "namespace_list" {
  type        = list(string)
  description = "Lista de namespaces exactos a filtrar cuando namespace_filter == 'exact'"
  default     = []
}
