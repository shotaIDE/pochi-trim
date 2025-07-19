import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pochi_trim/data/model/update_work_log_exception.dart';
import 'package:pochi_trim/ui/feature/home/edit_work_log_presenter.dart';
import 'package:pochi_trim/ui/feature/home/work_log_included_house_work.dart';

class EditWorkLogDialog extends ConsumerStatefulWidget {
  const EditWorkLogDialog({
    super.key,
    required this.workLogIncludedHouseWork,
  });

  final WorkLogIncludedHouseWork workLogIncludedHouseWork;

  /// ダイアログを表示して編集結果を返す
  static Future<bool?> show(
    BuildContext context,
    WorkLogIncludedHouseWork workLogIncludedHouseWork,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EditWorkLogDialog(
        workLogIncludedHouseWork: workLogIncludedHouseWork,
      ),
    );
  }

  @override
  ConsumerState<EditWorkLogDialog> createState() => _EditWorkLogDialogState();
}

class _EditWorkLogDialogState extends ConsumerState<EditWorkLogDialog> {
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.workLogIncludedHouseWork.completedAt;
  }

  @override
  Widget build(BuildContext context) {
    final houseWork = widget.workLogIncludedHouseWork.houseWork;

    return AlertDialog(
      title: Row(
        spacing: 12,
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            width: 32,
            height: 32,
            child: Text(
              houseWork.icon,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: Text(
              houseWork.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('日付'),
            subtitle: Text(
              DateFormat('yyyy/MM/dd (E)', 'ja').format(_selectedDateTime),
            ),
            onTap: _selectDate,
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('時刻'),
            subtitle: Text(
              DateFormat('HH:mm').format(_selectedDateTime),
            ),
            onTap: _selectTime,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: _saveWorkLog,
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ja', 'JP'),
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveWorkLog() async {
    // 未来の日時をチェック
    if (_selectedDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未来の日時は設定できません')),
      );
      return;
    }

    try {
      await ref.read(
        updateWorkLogDateTimeProvider(
          widget.workLogIncludedHouseWork.id,
          _selectedDateTime,
        ).future,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家事ログの日時を更新しました')),
      );
      Navigator.of(context).pop(true);
    } on UpdateWorkLogException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家事ログの更新に失敗しました。しばらくしてから再度お試しください')),
      );
    }
  }
}
