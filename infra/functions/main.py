# coding: utf-8

from firebase_admin import initialize_app
from firebase_functions import https_fn

initialize_app()

@https_fn.on_request()
def on_request_example(req: https_fn.Request) -> https_fn.Response:
    return https_fn.Response("Hello world!")
