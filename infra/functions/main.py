# coding: utf-8


from typing import Any

import google.cloud.firestore
from firebase_admin import firestore, initialize_app
from firebase_functions import https_fn

initialize_app()

@https_fn.on_call()
def generate_my_house(req: https_fn.CallableRequest) -> Any:
    user_id = req.auth.uid

    if user_id is None:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
                                  message="User is not authenticated")

    firestore_client: google.cloud.firestore.Client = firestore.client()

    _, house_doc_ref = firestore_client.collection("permissions").add({})

    # TODO: デバッグ用のコメントアウトなので、リリース時には元に戻す
    # house_doc_id = house_doc_ref.id
    house_doc_id = 'default-house-id'

    admin_doc_ref = firestore_client.collection("permissions").document(house_doc_id).collection("admin").document(user_id)
    admin_doc_ref.set({})

    print(f"House document has been created: ID = {house_doc_id}, admin user = {user_id}")

    return {
        "houseDocId": house_doc_id,
        "adminUser": user_id
    }
