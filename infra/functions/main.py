# coding: utf-8

import json

import google.cloud.firestore
from firebase_admin import auth, firestore, initialize_app
from firebase_functions import https_fn

initialize_app()

@https_fn.on_request()
def generate_my_house(req: https_fn.Request) -> https_fn.Response:
    auth_header = req.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return https_fn.Response("Authorization header required", status=401)

    id_token = auth_header.split("Bearer ")[1]
    try:
        decoded_token = auth.verify_id_token(id_token)
        user_id = decoded_token["uid"]
    except Exception as e:
        print(f"Error verifying token: {e}")

        return https_fn.Response("Invalid token", status=401)

    firestore_client: google.cloud.firestore.Client = firestore.client()

    _, house_doc_ref = firestore_client.collection("permissions").add({})

    house_doc_id = house_doc_ref.id

    admin_doc_ref = firestore_client.collection("permissions").document(house_doc_id).collection("admin").document(user_id)
    admin_doc_ref.set({})

    print(f"House document has been created: ID = {house_doc_id}, admin user = {user_id}")

    response_dic = {
        "houseDocId": house_doc_id,
        "adminUser": user_id
    }
    response_json = json.dumps(response_dic)
    return https_fn.Response(response_json, status=200, mimetype="application/json")
