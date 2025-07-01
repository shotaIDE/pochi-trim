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
            "houseDocId": first_house_id,
            "isNewHouse": False
        }

    print(f"User \"{user_id}\" is not belongs to any house, creating a new house...")

    # 家に参加していない場合、新規で家を作成
    _, house_doc_ref = firestore_client.collection("permissions").add({
        "adminUserIds": [user_id]
    })
    house_doc_id = house_doc_ref.id

    print(f"New house created: ID = {house_doc_id}, admin user = {user_id}")

    return {
        "houseDocId": house_doc_id,
        "isNewHouse": True
    }


@https_fn.on_call()
def delete_house_work(req: https_fn.CallableRequest) -> Any:
    """家事とその関連する家事ログを削除する関数

    トランザクションにおけるクエリ検索は Admin SDK でしか利用できないため、
    クライアントではなくサーバーサイド functions を用意している。
    """
    user_id = req.auth.uid

    if user_id is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="User is not authenticated"
        )

    # リクエストパラメータの取得
    house_id = req.data.get("houseId")
    house_work_id = req.data.get("houseWorkId")

    if not house_id or not house_work_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="houseId and houseWorkId are required"
        )

    firestore_client: google.cloud.firestore.Client = firestore.client()

    # 権限チェック: ユーザーが該当する家の管理者かどうか確認
    permissions_doc = firestore_client.collection("permissions").document(house_id).get()

    if not permissions_doc.exists:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.NOT_FOUND,
            message="House not found"
        )

    permissions_data = permissions_doc.to_dict()
    admin_user_ids = permissions_data.get("adminUserIds", [])

    if user_id not in admin_user_ids:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="User is not authorized to delete house work in this house"
        )

    try:
        # トランザクションで削除を実行
        @firestore.transactional
        def delete_house_work_transaction(transaction):
            house_ref = firestore_client.collection("houses").document(house_id)
            house_work_ref = house_ref.collection("houseWorks").document(house_work_id)

            # 読み込みは書き込み前に実行する（トランザクションの制約）
            # `transaction.get()` は遅延評価されるため、`list()` で即座に読み込みを実行
            work_logs_query = house_work_ref.collection("workLogs").where("houseWorkId", "==", house_work_id)
            work_logs_stream = transaction.get(work_logs_query)
            work_log_docs = list(work_logs_stream)

            transaction.delete(house_work_ref)

            for work_log_doc in work_log_docs:
                transaction.delete(work_log_doc.reference)

            return len(work_log_docs)

        transaction = firestore_client.transaction()
        deleted_work_logs_count = delete_house_work_transaction(transaction)

        print(f"Successfully deleted house work {house_work_id} and {deleted_work_logs_count} related work logs from house {house_id}")

        return {
            "success": True,
            "deletedHouseWorkId": house_work_id,
            "deletedWorkLogsCount": deleted_work_logs_count
        }

    except Exception as e:
        print(f"Error deleting house work: {e}")

        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="Failed to delete house work"
        )
