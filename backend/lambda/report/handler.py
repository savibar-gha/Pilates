import json
import os
from collections import defaultdict

import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])
ALLOWED_ORIGIN = os.environ.get("ALLOWED_ORIGIN", "*")

CORS_HEADERS = {
    "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
    "Access-Control-Allow-Headers": "content-type",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
}


def lambda_handler(event, context):
    items = _scan_all()

    # Conteo por pregunta -> respuesta -> cantidad
    conteo = defaultdict(lambda: defaultdict(int))
    total_respuestas_encuesta = len(items)

    for item in items:
        for r in item.get("respuestas", []):
            pregunta = r.get("pregunta", "Sin título")
            respuesta = r.get("respuesta")
            opciones = respuesta if isinstance(respuesta, list) else [respuesta]
            for opcion in opciones:
                if opcion:
                    conteo[pregunta][opcion] += 1

    reporte = [
        {
            "pregunta": pregunta,
            "opciones": [
                {"respuesta": opcion, "cantidad": cantidad}
                for opcion, cantidad in sorted(
                    opciones_dict.items(), key=lambda kv: -kv[1]
                )
            ],
        }
        for pregunta, opciones_dict in conteo.items()
    ]

    return _response(
        200,
        {
            "total_respuestas": total_respuestas_encuesta,
            "reporte": reporte,
        },
    )


def _scan_all():
    items = []
    kwargs = {}
    while True:
        resp = table.scan(**kwargs)
        items.extend(resp.get("Items", []))
        if "LastEvaluatedKey" not in resp:
            break
        kwargs["ExclusiveStartKey"] = resp["LastEvaluatedKey"]
    return items


def _response(status_code, payload):
    return {
        "statusCode": status_code,
        "headers": {**CORS_HEADERS, "Content-Type": "application/json"},
        "body": json.dumps(payload, ensure_ascii=False, default=str),
    }
