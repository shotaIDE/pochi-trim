# coding: utf-8

import google.cloud.firestore
from firebase_admin import firestore, initialize_app
from firebase_functions import https_fn

initialize_app()

@https_fn.on_request()
def generate_my_house(req: https_fn.Request) -> https_fn.Response:
    # TODO: 認証は必要？

    firestore_client: google.cloud.firestore.Client = firestore.client()

    _, house_doc_ref = firestore_client.collection("permissions").add({})

    house_doc_id = house_doc_ref.id
    print(f"House document has been created: ID = {house_doc_id}")

    return https_fn.Response(f"house document ID {house_doc_id} added.")
