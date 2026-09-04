import json
import os
import uuid
from datetime import datetime, timezone

import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])
ALLOWED_ORIGIN = os.environ.get("ALLOWED_ORIGIN", "*")

CORS_HEADERS = {
    "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
    "Access-Control-Allow-Headers": "content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
}


def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "JSON inválido"})

    respuestas = body.get("respuestas")
    if not respuestas or not isinstance(respuestas, list):
        return _response(400, {"error": "Falta el campo 'respuestas' (lista)"})

    item = {
        "id": str(uuid.uuid4()),
        "fecha": body.get("fecha") or datetime.now(timezone.utc).isoformat(),
        "encuesta": body.get("encuesta", "+Pilates"),
        "respuestas": respuestas,
    }

    table.put_item(Item=item)

    return _response(201, {"ok": True, "id": item["id"]})


def _response(status_code, payload):
    return {
        "statusCode": status_code,
        "headers": {**CORS_HEADERS, "Content-Type": "application/json"},
        "body": json.dumps(payload, ensure_ascii=False),
    }
