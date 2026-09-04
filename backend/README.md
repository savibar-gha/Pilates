# Backend +Pilates Encuesta — Setup en Mac mini

Arquitectura: **API Gateway (HTTP API) → Lambda (Python) → DynamoDB**

```
POST /respuestas  → guarda cada respuesta de la encuesta
GET  /reportes    → devuelve conteos agregados por pregunta/respuesta
```

## 1. Instalar herramientas (una sola vez)

```bash
# Homebrew (si no lo tenés)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# AWS CLI v2
brew install awscli

# Terraform
brew install terraform

# Verificar versiones
aws --version
terraform -version
```

## 2. Crear las Access Keys en AWS

1. Entrá a la consola de AWS → **IAM → Users** → creá un usuario (ej. `maspilates-deploy`) o usá tu usuario existente.
2. Asignale permisos (para simplificar en desarrollo podés usar `AdministratorAccess`; en producción conviene una policy más acotada a DynamoDB, Lambda, API Gateway, IAM).
3. **Security credentials → Create access key** → tipo "Command Line Interface (CLI)".
4. Guardá el `Access Key ID` y el `Secret Access Key` (esto último no se vuelve a mostrar).

## 3. Configurar AWS CLI en la Mac mini

```bash
aws configure
# AWS Access Key ID: <pegar>
# AWS Secret Access Key: <pegar>
# Default region name: us-east-1
# Default output format: json

# Verificar que quedó bien:
aws sts get-caller-identity
```

## 4. Clonar el proyecto

```bash
git clone https://github.com/savibar-gha/Pilates.git
cd Pilates/backend/terraform
```

## 5. Desplegar con Terraform

```bash
terraform init
terraform plan     # revisá qué se va a crear antes de aplicar
terraform apply    # escribí "yes" cuando lo pida
```

Al terminar, Terraform imprime el output `api_base_url`, algo como:
`https://abc123xyz.execute-api.us-east-1.amazonaws.com`

## 6. Probar el backend

```bash
# Guardar una respuesta de prueba
curl -X POST https://TU_API_URL/respuestas \
  -H "Content-Type: application/json" \
  -d '{"respuestas":[{"pregunta":"1. Test","respuesta":"Google"}]}'

# Ver el reporte agregado
curl https://TU_API_URL/reportes
```

## 7. Conectar el frontend

En `index.html`, agregar el `fetch()` al endpoint dentro del submit del formulario
(antes o en paralelo a la apertura de WhatsApp):

```js
fetch('https://TU_API_URL/respuestas', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(resultJSON)
});
```

## 8. Destruir todo (si en algún momento querés bajarlo)

```bash
terraform destroy
```

## Notas

- El estado de Terraform queda en `terraform.tfstate` **local** por defecto. Para
  trabajar en equipo o desde más de una máquina, conviene mover el backend a S3
  (ver bloque comentado en `providers.tf`).
- El costo con este diseño (DynamoDB on-demand + Lambda + HTTP API) es
  prácticamente $0 en reposo — solo pagás por invocación.
- Nunca subas tus Access Keys al repo. Quedan solo en `~/.aws/credentials` en tu Mac.
