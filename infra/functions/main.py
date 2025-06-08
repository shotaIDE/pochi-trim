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

    # すでに家に参加しているかチェック
    # collection group queryを使用してユーザーが管理者になっている家を検索
    admin_docs = firestore_client.collection_group("admin").where(firestore.FieldPath.document_id(), "==", user_id).limit(1).get()

    if admin_docs:
        # ユーザーが管理者として登録されている家が見つかった場合
        admin_doc = admin_docs[0]
        house_id = admin_doc.reference.parent.parent.id
        print(f"User {user_id} is already admin of house: {house_id}")
        return {
            "houseDocId": house_id
        }

    # 家に参加していない場合、新規で家を作成
    _, house_doc_ref = firestore_client.collection("permissions").add({})
    house_doc_id = house_doc_ref.id

    # 新規作成した家の管理者として権限を設定
    admin_doc_ref = firestore_client.collection("permissions").document(house_doc_id).collection("admin").document(user_id)
    admin_doc_ref.set({})

    print(f"New house created: ID = {house_doc_id}, admin user = {user_id}")

    return {
        "houseDocId": house_doc_id
    }
