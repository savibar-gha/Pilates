# Estado del proyecto +Pilates — Encuesta

Este archivo resume todo lo decidido y armado hasta ahora, para poder
retomarlo desde cualquier lado (ej. la Mac mini) sin perder contexto.

## 1. Frontend de la encuesta (`index.html`, raíz del repo)

- Publicado en GitHub Pages: **https://savibar-gha.github.io/Pilates/**
- Link corto: **https://tinyurl.com/MasPilates-Encuesta**
- Logo real (`logo.png`) en el header, con fondo transparente.
- Al enviar el formulario:
  - Arma un JSON con `{pregunta, respuesta}` por cada pregunta respondida.
  - Abre WhatsApp (`wa.me`) con ese resumen en texto, para enviar a
    **+598 92 878 066**.
  - **Pendiente:** agregar un `fetch()` al endpoint `POST /respuestas` del
    backend (ver sección 2) para que además de WhatsApp, quede guardado en
    DynamoDB. Ejemplo de snippet en `backend/README.md`, sección 8.
- `preview.png`: imagen para el preview al compartir el link (Open Graph /
  Twitter Card), con el logo + "Queremos conocerte un poco más". Ya está
  referenciada en las meta tags de `index.html`.

## 2. Backend (`backend/`, Terraform)

Arquitectura (ver `backend/README.md` para el detalle paso a paso):

```
Encuesta (GitHub Pages)  --POST /respuestas-->  API Gateway --> Lambda --> DynamoDB
Reporte (S3+CloudFront)  --GET  /reportes---->  API Gateway --> Lambda --> DynamoDB
                                                     ^
                                              JWT authorizer (Cognito)
```

- **DynamoDB**: tabla `maspilates-encuesta-respuestas`, pay-per-request.
- **Lambdas** (Python 3.12): `ingest` (guarda respuesta), `report` (agrega
  conteos por pregunta/respuesta).
- **API Gateway HTTP API**: `POST /respuestas` pública, `GET /reportes`
  protegida con JWT de Cognito.
- **Cognito User Pool**: login del staff (sin auto-registro, se da de alta
  usuario por usuario a mano).
- **S3 + CloudFront**: hosting privado de `backend/report.html` (el bucket
  no es público, solo CloudFront puede leerlo vía Origin Access Control).

### Estado del despliegue: **NO DESPLEGADO TODAVÍA**

Nada de esto corrió en AWS todavía — el Terraform está escrito y subido al
repo, pero falta ejecutar `terraform apply` desde la Mac mini.

### Próximos pasos pendientes (en orden)

1. En la Mac mini: instalar Homebrew, `awscli`, `terraform` (sección 1 del
   README de `backend/`).
2. Crear Access Keys en IAM y correr `aws configure`.
3. Clonar el repo, entrar a `backend/terraform`.
4. **Primera pasada**: `terraform init && terraform apply`.
5. Anotar los outputs: `api_base_url`, `report_site_url`,
   `cognito_hosted_ui_domain`, `cognito_client_id`, `cognito_user_pool_id`.
6. **Segunda pasada**: exportar `TF_VAR_report_callback_url` con el
   `report_site_url` real y volver a aplicar (Cognito necesita esa URL
   como callback del login).
7. Crear usuarios de staff en Cognito con `aws cognito-idp admin-create-user`.
8. Completar las 3 constantes (`API_BASE`, `COGNITO_DOMAIN`,
   `COGNITO_CLIENT_ID`) en `backend/report.html` y volver a aplicar
   Terraform para republicarlo en S3.
9. Agregar el `fetch()` pendiente en `index.html` (frontend de la encuesta)
   para que guarde en DynamoDB además de abrir WhatsApp.
10. Probar todo el flujo end-to-end: completar la encuesta → verificar que
    aparece en `GET /reportes` → verificar que el dashboard de
    `report.html` lo muestra.

## 3. Notas de seguridad / limpieza pendiente

- Los tokens de GitHub (fine-grained PAT) usados durante esta sesión para
  subir archivos ya cumplieron su función. **Revocarlos** desde
  https://github.com/settings/tokens?type=beta si no se van a seguir
  usando desde este chat.
- Nunca commitear Access Keys de AWS ni tokens al repo.
- El estado de Terraform (`terraform.tfstate`) queda local en la Mac mini
  por defecto. Si en algún momento se quiere trabajar desde más de una
  máquina, mover el backend de estado a S3 (bloque comentado en
  `backend/terraform/providers.tf`).

## 4. Decisiones de diseño ya tomadas (para no repreguntar)

- Arquitectura elegida: **Opción A serverless** (API Gateway + Lambda +
  DynamoDB), no relacional ni data lake — volumen esperado bajo/medio.
- Autenticación del back office: **Cognito** (login real por persona), no
  clave compartida.
- Hosting del back office: **AWS (S3+CloudFront)**, separado de la
  encuesta pública que sigue en GitHub Pages.
- Número de WhatsApp de destino vigente: **+598 92 878 066**.
