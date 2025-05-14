import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:house_worker/data/definition/app_definition.dart';
import 'package:in_app_review/in_app_review.dart';

class UpdateAppScreen extends StatefulWidget {
  const UpdateAppScreen({super.key});

  static const name = 'UpdateAppScreen';

  static MaterialPageRoute<UpdateAppScreen> route() =>
      MaterialPageRoute<UpdateAppScreen>(
        builder: (_) => const UpdateAppScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  State<UpdateAppScreen> createState() => _UpdateAppScreenState();
}

class _UpdateAppScreenState extends State<UpdateAppScreen> {
  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _showDialog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Stack(children: [SizedBox.expand()]));
  }

  Future<void> _showDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return PopScope(
          // Android OSのバックボタンによりダイアログを閉じることができないようにする
          canPop: false,
          child: AlertDialog(
            title: const Text('アプリのアップデートをお願いします'),
            content: const Text(
              '新しいバージョンがリリースされています。より良いパフォーマンスを得るために、アップデートしてご利用ください',
            ),
            actions: [
              TextButton(
                child: const Text('アップデートする'),
                onPressed: () async {
                  await InAppReview.instance.openStoreListing(
                    appStoreId: appStoreId,
                  );
                },
              ),
            ],
          ),
        );
      },
      barrierDismissible: false,
    );
  }
}
