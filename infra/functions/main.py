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
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="User is not authenticated"
        )

    firestore_client: google.cloud.firestore.Client = firestore.client()

    # すでに家に参加しているかチェック
    # adminUserIdsにuser_idが含まれる権限ドキュメントを検索
    permissions_collection = firestore_client.collection("permissions")
    permission_docs = permissions_collection.where("adminUserIds", "array_contains", user_id).get()

    if permission_docs and len(permission_docs) >= 1:
        # ユーザーが管理者として登録されている家が見つかった場合
        house_id_list = [permission_doc.id for permission_doc in permission_docs]
        print(f"User \"{user_id}\" is already admin of houses: {house_id_list}")

        first_house_id = house_id_list[0]
        print(f"Returning first house ID: {first_house_id}")

        return {
            "houseDocId": first_house_id
        }

    print(f"User \"{user_id}\" is not belongs to any house, creating a new house...")

    # 家に参加していない場合、新規で家を作成
    _, house_doc_ref = firestore_client.collection("permissions").add({
        "adminUserIds": [user_id]
    })
    house_doc_id = house_doc_ref.id

    print(f"New house created: ID = {house_doc_id}, admin user = {user_id}")

    return {
        "houseDocId": house_doc_id
    }


