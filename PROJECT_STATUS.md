# Estado del proyecto +Pilates — Encuesta

Este archivo resume todo lo decidido y armado hasta ahora, para poder
retomarlo desde cualquier lado (ej. la Mac mini) sin perder contexto.

## 1. Frontend de la encuesta (`index.html`, raíz del repo)

- Publicado en GitHub Pages: **https://savibar-gha.github.io/Pilates/**
- Link corto: **https://tinyurl.com/MasPilates-Encuesta**
- Logo real (`logo.png`) en el header, con fondo transparente.
- Al enviar el formulario:
  - Valida que las 6 preguntas estén respondidas antes de dejar enviar
    (resalta en tono terracota la primera pregunta pendiente con un
    mensaje amable, sin popup del navegador).
  - Hace `fetch()` a `POST /respuestas` para guardar en DynamoDB.
  - **Ya NO envía por WhatsApp** — se sacó el `wa.me` y todo lo relacionado
    a pedido explícito (se decidió mantener el dato solo en AWS).
  - Pantalla final: "¡Gracias por tu tiempo! 🧡" + confirmación, sin
    mostrar texto técnico interno.
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
  conteos + porcentaje por pregunta/respuesta).
- **API Gateway HTTP API**: `POST /respuestas` pública, `GET /reportes`
  protegida con JWT de Cognito. CORS habilitado tanto para el origen de
  GitHub Pages (encuesta) como para el de CloudFront (dashboard).
- **Cognito User Pool**: login del staff (sin auto-registro). Usuario
  creado: `staff`.
- **S3 + CloudFront**: hosting privado de `backend/report.html` (el bucket
  no es público, solo CloudFront puede leerlo vía Origin Access Control).

### Estado del despliegue: **DESPLEGADO Y FUNCIONANDO** (cuenta AWS dev 653714462550)

Outputs de Terraform:
```
api_base_url             = https://jnljl8iff1.execute-api.us-east-1.amazonaws.com
cognito_client_id        = 5iieidctajmsdud3kf4rrib06j
cognito_hosted_ui_domain = maspilates-encuesta-report.auth.us-east-1.amazoncognito.com
cognito_user_pool_id     = us-east-1_tlgFECQNF
dynamodb_table_name      = maspilates-encuesta-respuestas
report_site_url          = https://dxgmqiih8zjxq.cloudfront.net/report.html
```

Dashboard de reportes: **https://dxgmqiih8zjxq.cloudfront.net/report.html**
Login staff: usuario `staff`, contraseña `PilatesStaff2026!`.

En la Mac mini: AWS CLI + Terraform instalados vía Homebrew. Profile a usar
siempre: `AWS_PROFILE=pilates-app-dev` (asume el rol
`OrganizationAccountAccessRole` en la cuenta dev usando como source
`pilates-management`, la cuenta de la Organization).

### Pendiente

1. **Limpiar datos de prueba en DynamoDB**: hay ~6 filas de prueba (1 de
   humo "Test smoke" + 5 respuestas random cargadas para probar el
   dashboard) que hay que borrar antes de que entren respuestas reales.
2. Confirmar que GitHub Pages ya sirve la versión sin WhatsApp (se pusheó
   a `main`, puede tardar 1-2 min en propagar).
3. Revocar el token de GitHub (fine-grained PAT) usado para subir este
   archivo desde el celular, si ya no se va a usar:
   https://github.com/settings/tokens?type=beta

## 3. Notas de seguridad

- Nunca commitear Access Keys de AWS ni tokens al repo.
- El estado de Terraform (`terraform.tfstate`) queda local en la Mac mini
  por defecto (está en `.gitignore`, no se sube). Si en algún momento se
  quiere trabajar desde más de una máquina, mover el backend de estado a
  S3 (bloque comentado en `backend/terraform/providers.tf`).

## 4. Decisiones de diseño ya tomadas (para no repreguntar)

- Arquitectura elegida: **Opción A serverless** (API Gateway + Lambda +
  DynamoDB), no relacional ni data lake — volumen esperado bajo/medio.
- Autenticación del back office: **Cognito** (login real por persona), no
  clave compartida.
- Hosting del back office: **AWS (S3+CloudFront)**, separado de la
  encuesta pública que sigue en GitHub Pages. Son páginas totalmente
  independientes, sin link entre sí — la única conexión es vía backend.
  `report.html` es de uso exclusivo del staff.
- Se sacó el envío por WhatsApp: los resultados quedan solo en AWS.
- Preguntas 1, 4, 5 y 6 son de una sola opción (radio); preguntas 2 y 3
  permiten marcar varias a propósito (checkbox).
- Cada opción del reporte muestra cantidad + porcentaje sobre el total de
  esa pregunta (no sobre el total de encuestas, para que tenga sentido con
  preguntas de selección múltiple).
