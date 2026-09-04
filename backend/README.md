# Backend +Pilates Encuesta — Setup en Mac mini

Arquitectura:

```
Encuesta (GitHub Pages)  --POST /respuestas-->  API Gateway --> Lambda --> DynamoDB
Reporte (S3+CloudFront)  --GET  /reportes---->  API Gateway --> Lambda --> DynamoDB
                                                     ^
                                            valida token JWT
                                                     |
                                              Cognito User Pool (login del staff)
```

- `POST /respuestas`: pública, la usa el formulario de la encuesta.
- `GET /reportes`: protegida — requiere estar logueado con un usuario de Cognito.
- `report.html`: dashboard con gráficos de barras por pregunta, hosteado en
  S3 + CloudFront (privado: solo se accede vía CloudFront, no directo al bucket).

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

1. Consola de AWS → **IAM → Users** → creá un usuario (ej. `maspilates-deploy`) o usá el tuyo.
2. Asignale permisos (para simplificar en desarrollo `AdministratorAccess` está bien;
   en producción conviene acotar a DynamoDB, Lambda, API Gateway, S3, CloudFront, Cognito, IAM).
3. **Security credentials → Create access key** → tipo "Command Line Interface (CLI)".
4. Guardá el `Access Key ID` y el `Secret Access Key`.

## 3. Configurar AWS CLI en la Mac mini

```bash
aws configure
# AWS Access Key ID: <pegar>
# AWS Secret Access Key: <pegar>
# Default region name: us-east-1
# Default output format: json

aws sts get-caller-identity   # verificación
```

## 4. Clonar el proyecto

```bash
git clone https://github.com/savibar-gha/Pilates.git
cd Pilates/backend/terraform
```

## 5. Desplegar con Terraform (dos pasadas)

Cognito necesita saber la URL de `report.html` como "callback URL" del login,
pero esa URL (el dominio de CloudFront) recién existe después de crear
CloudFront. Por eso el despliegue es en dos pasos:

**Primera pasada** (con la URL de callback provisoria por defecto):

```bash
terraform init
terraform plan
terraform apply
```

Al terminar, anotá estos outputs:
- `api_base_url`
- `report_site_url`
- `cognito_hosted_ui_domain`
- `cognito_client_id`
- `cognito_user_pool_id`

**Segunda pasada**, ahora que ya existe la URL real de CloudFront:

```bash
export TF_VAR_report_callback_url="$(terraform output -raw report_site_url)"
terraform apply
```

Esto actualiza el User Pool Client de Cognito para que redirija correctamente
después del login.

## 6. Crear un usuario de staff en Cognito

Como el user pool no permite auto-registro, das de alta vos a cada persona:

```bash
aws cognito-idp admin-create-user \
  --user-pool-id "$(terraform output -raw cognito_user_pool_id)" \
  --username sofia@maspilates.com \
  --user-attributes Name=email,Value=sofia@maspilates.com Name=email_verified,Value=true \
  --temporary-password "Cambiar123!"
```

La persona inicia sesión con esa contraseña temporal y Cognito le va a pedir
que la cambie la primera vez.

## 7. Probar el backend

```bash
API=$(terraform output -raw api_base_url)

# Guardar una respuesta de prueba (sin login, es pública)
curl -X POST "$API/respuestas" \
  -H "Content-Type: application/json" \
  -d '{"respuestas":[{"pregunta":"1. Test","respuesta":"Google"}]}'

# /reportes va a rechazar esto porque no tiene token:
curl "$API/reportes"   # 401
```

## 8. Conectar el frontend de la encuesta

En `index.html` (el de la encuesta), agregar el `fetch()` dentro del submit
del formulario, en paralelo a la apertura de WhatsApp:

```js
fetch('https://TU_API_URL/respuestas', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(resultJSON)
});
```

## 9. Completar y publicar `report.html`

Editar las 3 constantes al principio del `<script>` de `report.html` con los
outputs de Terraform:

```js
const API_BASE         = 'https://TU_API_URL';
const COGNITO_DOMAIN    = 'TU_DOMINIO.auth.us-east-1.amazoncognito.com';
const COGNITO_CLIENT_ID = 'TU_CLIENT_ID';
```

Terraform ya sube este archivo al bucket S3 automáticamente en cada `apply`
(recurso `aws_s3_object.report_html`), así que después de editarlo alcanza
con volver a correr `terraform apply` para republicarlo.

## 10. Destruir todo (si en algún momento querés bajarlo)

```bash
terraform destroy
```

## Notas de seguridad

- El estado de Terraform queda en `terraform.tfstate` **local** por defecto.
  Para trabajar en equipo o desde más de una máquina, conviene mover el
  backend a S3 (ver bloque comentado en `providers.tf`).
- Costo: DynamoDB on-demand + Lambda + HTTP API + Cognito (primeros 50 MAU
  gratis) + CloudFront (capa gratuita generosa) → prácticamente $0 con este volumen.
- Nunca subas tus Access Keys al repo. Quedan solo en `~/.aws/credentials` en tu Mac.
- El bucket S3 de `report.html` es **privado**; solo CloudFront puede leerlo
  (Origin Access Control), y encima los datos reales siguen protegidos por
  el login de Cognito en la API.
