#!/bin/bash
set -e

ACCOUNT_ID=$1
VISIT_ID=$2

# PostgreSQL query to get image path
echo "Consultando PostgreSQL..."
IMAGE_PATH=$(psql "host=$DB_HOST dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD" -t -c "
  SELECT rv.image 
  FROM routes_visit 
  INNER JOIN public.routes_visitpicture rv ON routes_visit.id = rv.visit_id 
  WHERE routes_visit.account_id = $ACCOUNT_ID AND routes_visit.id = $VISIT_ID
")

IMAGE_PATH=$(echo $IMAGE_PATH | xargs) # Trim whitespace

if [[ -z "$IMAGE_PATH" ]]; then
  echo "No se encontró la ruta de imagen para la visita dada."
  exit 1
fi

echo "Ruta obtenida: $IMAGE_PATH"

# Request restore from Glacier Deep Archive
echo "Solicitando restauración del objeto $IMAGE_PATH en S3..."
aws s3api restore-object \
  --bucket "$BUCKET_NAME" \
  --key "$IMAGE_PATH" \
  --restore-request '{"Days":5,"GlacierJobParameters":{"Tier":"Standard"}}'

# Optional monitoring (polling restore status)
echo "Puedes verificar la restauración con:"
echo "aws s3api head-object --bucket $BUCKET_NAME --key $IMAGE_PATH"

echo "Cuando el objeto esté restaurado, ejecuta para descargar:"
echo "aws s3 cp s3://$BUCKET_NAME/$IMAGE_PATH ./$(basename $IMAGE_PATH)"