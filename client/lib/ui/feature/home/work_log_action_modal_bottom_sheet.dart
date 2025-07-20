import 'package:flutter/material.dart';

enum WorkLogAction { edit, delete }

Future<WorkLogAction?> showWorkLogActionModalBottomSheet(
  BuildContext context,
) {
  return showModalBottomSheet<WorkLogAction>(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        // ボトムシート全体は左右のセーフエリア内に収まるため、ボトムシート内のコンテンツは
        // セーフエリアの左右の余白を無視して表示する
        left: false,
        right: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('編集する'),
              onTap: () => Navigator.of(context).pop(WorkLogAction.edit),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('削除する'),
              onTap: () => Navigator.of(context).pop(WorkLogAction.delete),
            ),
          ],
        ),
      );
    },
    clipBehavior: Clip.antiAlias,
  );
}
