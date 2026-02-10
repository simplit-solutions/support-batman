# GCP Cloud Monitoring Dashboard - Monitoreo Cross-Project

Dashboard centralizado en GCP Cloud Monitoring para monitorear un clúster GKE o Cloud SQL de **otro proyecto GCP**.

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
        ┌──────────┴──────────┐
        │                     │
┌───────▼──────────┐  ┌───────▼──────────┐
│ Proyecto K8s     │  │ Proyecto DB      │
│ (producción)     │  │ (producción)     │
│                  │  │                  │
│ └─ GKE Cluster   │  │ └─ Cloud SQL     │
└──────────────────┘  └──────────────────┘
```

## 📊 Tipos de Dashboards

### 🚀 **Kubernetes Dashboard** (`deploy-kubernetes.yml`)

Monitorea un clúster GKE con métricas de:
- Instance group size
- CPU/Memory utilization (QA1, QA2, QA3)
- Container metrics y HPA
- Alertas: CPU, Memoria, Reinicios, Pods fallidos

**Variables necesarias:**
- `monitoring_project_id`
- `monitoring_region`
- `target_project_id`
- `cluster_name`

### 💾 **Database Dashboard** (`deploy-database.yml`)

Monitorea Cloud SQL con métricas de:
- CPU utilization
- Memory usage
- Database calls/queries
- Connections
- Disk utilization
- Instance up status
- Alertas: CPU, Memoria, Disco

**Variables necesarias:**
- `monitoring_project_id`
- `monitoring_region`
- `database_project_id`
- `database_instance`
- `database_name`

## 🚀 Uso desde GitHub Actions

### Opción 1: Desplegar Kubernetes Dashboard

1. Ve a **Actions** → **Deploy Kubernetes Dashboard**
2. Click en **Run workflow**
3. Completa solo los campos de Kubernetes:
   - `monitoring_project_id`
   - `monitoring_region`
   - `target_project_id`
   - `cluster_name`
4. Click en **Run workflow**

### Opción 2: Desplegar Database Dashboard

1. Ve a **Actions** → **Deploy Database Dashboard**
2. Click en **Run workflow**
3. Completa solo los campos de Database:
   - `monitoring_project_id`
   - `monitoring_region`
   - `database_project_id`
   - `database_instance`
   - `database_name`
4. Click en **Run workflow**

## 📋 Requisitos Previos

### GCP
- ✅ Dos proyectos GCP:
  - **Proyecto A (Monitoreo)**: Donde se crearán los dashboards
  - **Proyecto B (K8s/DB)**: Contiene el recurso a monitorear

- ✅ El cluster GKE o Cloud SQL ya tiene Google Cloud Monitoring habilitado

### GitHub Secrets
Configura estos secrets en tu repositorio (Settings > Secrets):

```
GCP_SA_KEY                    # JSON de Service Account
# O para Workload Identity:
WORKLOAD_IDENTITY_PROVIDER    # Tu Workload Identity Provider
GCP_SERVICE_ACCOUNT           # Tu Service Account
SLACK_WEBHOOK_URL             # (Opcional) Webhook de Slack
```

### Permisos Necesarios

**En Proyecto A (Monitoreo):**
```
roles/monitoring.admin
roles/monitoring.alertPolicyEditor
roles/monitoring.dashboardEditor
roles/monitoring.notificationChannelEditor
```

**En Proyecto B (K8s/DB):**
```
roles/monitoring.metricReader (solo lectura de métricas)
```

## 🔐 Autenticación

### Service Account (Recomendado para CI/CD)
```bash
# Crea una Service Account
gcloud iam service-accounts create github-actions

# Asigna permisos en ambos proyectos
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member=serviceAccount:github-actions@PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/monitoring.admin

# Genera la clave JSON
gcloud iam service-accounts keys create sa-key.json \
  --iam-account=github-actions@PROJECT_ID.iam.gserviceaccount.com

# Agregala como secret GCP_SA_KEY en GitHub
```

### Workload Identity (Más seguro)
Sigue la documentación oficial: https://github.com/google-github-actions/auth#workload-identity-federation

## 🔔 Configurar Notificaciones

### Email
En el workflow, proporciona los emails en formato JSON:
```
["ops@company.com", "devops@company.com"]
```

### Slack
1. Ve a tu workspace de Slack
2. Crea una Incoming Webhook en Slack App Directory
3. Obtén la URL (empieza con `https://hooks.slack.com/...`)
4. Agregala como secret `SLACK_WEBHOOK_URL` en GitHub
5. En el workflow, selecciona el canal: `#alerts-k8s`

## 📈 Acceder al Dashboard

Una vez desplegado:

```
https://console.cloud.google.com/monitoring/dashboards?project=YOUR_MONITORING_PROJECT_ID
```

O desde el output del workflow.

## 🔄 Actualizar un Dashboard

Para actualizar valores o agregar nuevos widgets:

1. Edita los archivos en `terraform/dashboard/`
2. Commit y push
3. Ejecuta el workflow correspondiente nuevamente

## 🧹 Eliminar Recursos

```bash
cd terraform/dashboard
terraform destroy
```

## 📚 Variables Configurables

### Kubernetes Dashboard

| Variable | Ejemplo | Descripción |
|----------|---------|-------------|
| `monitoring_project_id` | `monitoring-prod` | Proyecto central |
| `monitoring_region` | `us-central1` | Región de monitoreo |
| `target_project_id` | `prod-k8s` | Proyecto del K8s |
| `cluster_name` | `gke-prod` | Nombre del clúster |
| `enable_alerts` | `true` | Activar alertas |

### Database Dashboard

| Variable | Ejemplo | Descripción |
|----------|---------|-------------|
| `monitoring_project_id` | `monitoring-prod` | Proyecto central |
| `monitoring_region` | `us-central1` | Región de monitoreo |
| `database_project_id` | `prod-db` | Proyecto del Cloud SQL |
| `database_instance` | `prod-mysql-01` | Nombre de instancia |
| `database_name` | `myapp_db` | Nombre de DB |
| `enable_alerts` | `true` | Activar alertas |

## 🔍 Troubleshooting

### "Permission denied"
- Verifica que el Service Account tiene permisos en ambos proyectos
- Confirma que `GCP_SA_KEY` es válido

### Dashboard no muestra datos
- Espera 2-3 minutos (Cloud Monitoring tarda en actualizar)
- Verifica que el recurso existe en el proyecto

### Alertas no se envían
- Confirma que aceptaste la invitación de email
- Para Slack, verifica que la URL del webhook es válida

## 📝 Estructura del Proyecto

```
support-batman/
├── .github/
│   └── workflows/
│       ├── deploy-kubernetes.yml    # Workflow para K8s
│       ├── deploy-database.yml      # Workflow para DB
│       └── restore-download.yml     # Otro workflow
├── terraform/
│   └── dashboard/
│       ├── main.tf                  # Dashboards y alertas
│       ├── variables.tf             # Variables
│       ├── outputs.tf               # Outputs
│       ├── versions.tf              # Versiones de providers
│       ├── terraform.tfvars.example # Ejemplo de variables
│       └── README.md                # Esta documentación
└── ...
```

## 🆘 Soporte

Para más información:
- [Cloud Monitoring API](https://cloud.google.com/monitoring/api)
- [GKE Monitoring](https://cloud.google.com/kubernetes-engine/docs/how-to/monitoring)
- [Cloud SQL Monitoring](https://cloud.google.com/sql/docs/mysql/monitoring)
