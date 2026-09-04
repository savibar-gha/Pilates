import os

SHARED_SECRET = os.environ["REPORT_SECRET"]


def lambda_handler(event, context):
    headers = event.get("headers") or {}
    # los headers llegan en minúscula en API Gateway v2
    provided = headers.get("x-api-key", "")

    is_authorized = provided == SHARED_SECRET

    return {
        "isAuthorized": is_authorized
    }
