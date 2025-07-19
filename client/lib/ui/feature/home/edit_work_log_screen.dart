import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pochi_trim/data/model/update_work_log_exception.dart';
import 'package:pochi_trim/ui/feature/home/edit_work_log_presenter.dart';
import 'package:pochi_trim/ui/feature/home/work_log_included_house_work.dart';

class EditWorkLogScreen extends ConsumerStatefulWidget {
  const EditWorkLogScreen({
    super.key,
    required this.workLogIncludedHouseWork,
  });

  final WorkLogIncludedHouseWork workLogIncludedHouseWork;

  static const name = 'EditWorkLogScreen';

  static MaterialPageRoute<bool> route(
    WorkLogIncludedHouseWork workLogIncludedHouseWork,
  ) => MaterialPageRoute<bool>(
    builder: (_) => EditWorkLogScreen(
      workLogIncludedHouseWork: workLogIncludedHouseWork,
    ),
    settings: const RouteSettings(name: name),
  );

  @override
  ConsumerState<EditWorkLogScreen> createState() => _EditWorkLogScreenState();
}

class _EditWorkLogScreenState extends ConsumerState<EditWorkLogScreen> {
  late DateTime _selectedDateTime;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.workLogIncludedHouseWork.completedAt;
  }

  @override
  Widget build(BuildContext context) {
    final houseWork = widget.workLogIncludedHouseWork.houseWork;

    return Scaffold(
      appBar: AppBar(
        title: const Text('家事ログの編集'),
        actions: [
          TextButton(
            onPressed: _saveWorkLog,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 家事情報の表示
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: 48,
                        height: 48,
                        child: Text(
                          houseWork.icon,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              houseWork.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '家事ログの完了時刻を編集できます',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(150),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 日時選択セクション
              Text(
                '完了日時',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 日付選択
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('日付'),
                  subtitle: Text(
                    DateFormat('yyyy年M月d日(E)', 'ja').format(_selectedDateTime),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _selectDate,
                ),
              ),

              const SizedBox(height: 8),

              // 時刻選択
              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('時刻'),
                  subtitle: Text(
                    DateFormat('HH:mm').format(_selectedDateTime),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _selectTime,
                ),
              ),

              const SizedBox(height: 24),

              // 現在の設定日時の表示
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '完了日時',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'yyyy年M月d日(E) HH:mm',
                        'ja',
                      ).format(_selectedDateTime),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
