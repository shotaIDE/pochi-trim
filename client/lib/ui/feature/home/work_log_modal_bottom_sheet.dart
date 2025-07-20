import 'package:flutter/material.dart';

enum WorkLogAction { edit, delete }

Future<WorkLogAction?> showWorkLogActionModalBottomSheet(
  BuildContext context,
) async {
  return showModalBottomSheet<WorkLogAction>(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
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
