#!/bin/bash
set -e

# -----------------------------------------------------------------------------
# Configuración de Conexiones
# -----------------------------------------------------------------------------
: "${DB_HOST:?Falta DB_HOST}"
: "${DB_PORT:?Falta DB_PORT}"
: "${DB_NAME:?Falta DB_NAME}"
: "${DB_USER:?Falta DB_USER}"
: "${DB_PASSWORD:?Falta DB_PASSWORD}"
: "${DB_SSLMODE:?Falta DB_SSLMODE}"
: "${AWS_ACCESS_KEY_ID:?Falta AWS_ACCESS_KEY_ID}"
: "${AWS_SECRET_ACCESS_KEY:?Falta AWS_SECRET_ACCESS_KEY}"
: "${AWS_REGION:?Falta AWS_REGION}"
: "${BUCKET_NAME:?Falta BUCKET_NAME}"

ACCOUNT_ID=$1
VISIT_ID=$2

if [[ -z "$ACCOUNT_ID" || -z "$VISIT_ID" ]]; then
  echo "Uso: $0 <account_id> <visit_id>"
  exit 1
fi

# PostgreSQL query to get image path
echo "[INFO] Consultando PostgreSQL en ${DB_HOST}:${DB_PORT}/${DB_NAME}..."
IMAGE_PATH=$(psql "host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD sslmode=$DB_SSLMODE" -t -c "
  SELECT rv.image
  FROM routes_visit
  INNER JOIN public.routes_visitpicture rv ON routes_visit.id = rv.visit_id
  WHERE routes_visit.account_id = $ACCOUNT_ID AND routes_visit.id = $VISIT_ID
")

IMAGE_PATH=$(echo $IMAGE_PATH | xargs) # Trim whitespace

if [[ -z "$IMAGE_PATH" ]]; then
  echo "[ERROR] No se encontró la ruta de imagen para account_id=$ACCOUNT_ID, visit_id=$VISIT_ID."
  exit 1
fi

echo "[INFO] Ruta obtenida: $IMAGE_PATH"

# Configurar AWS CLI (opcional si usas perfil default)
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION

echo "[INFO] Solicitando restauración del objeto en S3: s3://$BUCKET_NAME/$IMAGE_PATH..."
aws s3api restore-object \
  --bucket "$BUCKET_NAME" \
  --key "$IMAGE_PATH" \
  --restore-request '{"Days":5,"GlacierJobParameters":{"Tier":"Standard"}}'

# Mensajes de monitoreo y descarga
echo "[INFO] Verificar estado de restauración con:"
echo " aws s3api head-object --bucket $BUCKET_NAME --key $IMAGE_PATH"

echo "Cuando el archivo indique 'ongoing-request=\"false\"', descargar con:"
echo " aws s3 cp s3://$BUCKET_NAME/$IMAGE_PATH ./$(basename $IMAGE_PATH)"