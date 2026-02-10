# GCP Cloud Monitoring Dashboard - Monitoreo Cross-Project

Dashboard centralizado en GCP Cloud Monitoring para monitorear un clúster GKE de **otro proyecto GCP**.

## 🎯 Arquitectura

```
┌─────────────────────────────────────┐
│   Proyecto Central de Monitoreo     │
│  (monitoring-central-project)       │
│                                     │
│  ├─ Dashboards Cloud Monitoring    │
│  ├─ Alert Policies                 │
│  ├─ Notification Channels          │
│  └─ SLOs (Service Level Objectives)│
└──────────────────┬──────────────────┘
                   │
         Lee métricas desde
                   │
┌──────────────────▼──────────────────┐
│   Proyecto de Producción            │
│  (production-k8s-project)           │
│                                     │
│  └─ GKE Cluster                     │
│     (con Cloud Monitoring activo)  │
└─────────────────────────────────────┘
```

## 📊 Qué se monitorea

El dashboard muestra en **tiempo real**:

### Salud de Nodos
- CPU usage por nodo
- Memoria disponible y utilizada
- Disco disponible
- Estado de red

### Pods
- Cantidad de pods running vs failed
- Tasa de reinicios (restarts)
- CPU y memoria consumida
- Tráfico de red (in/out)
- Errores de red

### Contenedores
- CPU usage por contenedor
- Memoria working set
- Tasa de reinicios
- Uptime

### Alertas Automáticas
- CPU de nodos > 80%
- Memoria de nodos > 85%
- Pods con reinicios frecuentes (>5 en 10min)
- Pods en estado fallido

## 🚀 Requisitos Previos

### GCP
- ✅ Dos proyectos GCP:
  - **Proyecto A (Monitoreo)**: Donde se crearán los dashboards
  - **Proyecto B (Producción)**: Contiene el GKE cluster

- ✅ El cluster GKE ya tiene Google Cloud Monitoring habilitado
  - Puedes verificar: `gcloud container clusters describe CLUSTER_NAME --project=PROJECT_B`

### Localmente
- `terraform` v1.0+
- `gcloud` CLI configurada
- Permisos suficientes en ambos proyectos

### Permisos Necesarios

**En Proyecto A (Monitoreo):**
```
roles/monitoring.admin
roles/monitoring.alertPolicyEditor
roles/monitoring.dashboardEditor
roles/monitoring.notificationChannelEditor
```

**En Proyecto B (Producción):**
```
roles/monitoring.metricReader (solo lectura de métricas)
```

## 🔧 Instalación

### 1. Clonar y preparar variables

```bash
cd terraform/dashboard
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con tus valores:

```hcl
# Proyecto donde se crearán dashboards y alertas
monitoring_project_id = "your-monitoring-project-id"
monitoring_region     = "us-central1"

# Proyecto que contiene el cluster GKE
target_project_id = "your-production-project-id"
cluster_name      = "your-gke-cluster-name"

# Notificaciones
notification_emails = ["your-email@company.com"]
slack_webhook_url   = "https://hooks.slack.com/services/..."  # Opcional
```

### 2. Autenticar con GCP

```bash
gcloud auth application-default login

# Alternativamente, con Service Account
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/sa-key.json"
```

### 3. Inicializar Terraform

```bash
terraform init
```

### 4. Revisar cambios

```bash
terraform plan
```

### 5. Aplicar

```bash
terraform apply
```

## 📈 Acceder al Dashboard

Una vez aplicado, accede de dos formas:

### Opción 1: URL directa
```
https://console.cloud.google.com/monitoring/dashboards?project=YOUR_MONITORING_PROJECT_ID
```

### Opción 2: Con Terraform
```bash
terraform output gcp_console_url
```

Luego busca el dashboard: **"GKE Cluster - CLUSTER_NAME"**

## 🔔 Configurar Notificaciones

### Email
Solo necesitas agregar los emails en `terraform.tfvars`:
```hcl
notification_emails = ["ops@company.com", "devops@company.com"]
```

### Slack
1. Ve a tu workspace de Slack
2. Crea una app (o usa Incoming Webhooks)
3. Obtén el webhook URL (empieza con `https://hooks.slack.com/...`)
4. Agrega a `terraform.tfvars`:
```hcl
slack_webhook_url = "https://hooks.slack.com/services/xxx/yyy/zzz"
slack_channel_name = "#alerts-k8s"
```

## 📊 Variables Configurables

| Variable | Tipo | Requerido | Descripción |
|----------|------|-----------|-------------|
| `monitoring_project_id` | string | ✅ | Proyecto central de monitoreo |
| `target_project_id` | string | ✅ | Proyecto con el cluster GKE |
| `cluster_name` | string | ✅ | Nombre del cluster a monitorear |
| `enable_alerts` | bool | ❌ | Activar alertas (default: true) |
| `notification_emails` | list(string) | ❌ | Emails para notificaciones |
| `slack_webhook_url` | string | ❌ | Webhook de Slack |
| `slack_channel_name` | string | ❌ | Canal Slack (default: #alerts) |

## 📤 Outputs

```bash
terraform output

# Resultados:
# - monitoring_project_id: Tu proyecto de monitoreo
# - target_project_id: Tu proyecto de producción
# - dashboard_id: ID del dashboard creado
# - alert_policies: IDs de las políticas de alerta
# - notification_channels: IDs de canales de notificación
# - gcp_console_url: URL directa al dashboard
```

## 🧹 Eliminar Recursos

```bash
terraform destroy
```

Confirma cuando se solicite.

## 🔐 Consideraciones de Seguridad

- Las credenciales de Slack se guardan como `sensitive` en state
- Usa `terraform.tfvars` local (agrégalo a `.gitignore`)
- Considera usar un `terraform.tfvars.enc` con Terraform Cloud
- Revisa permisos IAM en ambos proyectos regularmente

## 🐛 Troubleshooting

### Error: "Permission denied" en proyecto de producción
- Verifica que tu usuario tenga `roles/monitoring.metricReader` en el proyecto B

### Dashboard no muestra datos
- Espera 2-3 minutos (Cloud Monitoring tarda en actualizar)
- Verifica que el cluster tiene `monitoring_config.enable_components = ["SYSTEM_COMPONENTS"]`

### Alertas no se envían
- Confirma que aceptaste la invitación de email
- Para Slack, verifica el webhook URL en la app de Slack

## 📚 Recursos Útiles

- [Cloud Monitoring API](https://cloud.google.com/monitoring/api)
- [GKE Monitoring Best Practices](https://cloud.google.com/kubernetes-engine/docs/how-to/monitoring)
- [Alert Policies Guide](https://cloud.google.com/monitoring/alerts/how-tos)

## 📝 Ejemplo Completo

Ver archivos en este directorio:
- `main.tf`: Definición de dashboard y alertas
- `variables.tf`: Variables del módulo
- `outputs.tf`: Salidas
- `versions.tf`: Versiones de providers
- `terraform.tfvars.example`: Ejemplo de configuración
