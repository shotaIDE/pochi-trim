import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pochi_trim/ui/component/house_work_icon.dart';
import 'package:pochi_trim/ui/feature/home/work_log_included_house_work.dart';

Future<DateTime?> showEditWorkLogDialog(
  BuildContext context, {
  required WorkLogIncludedHouseWork workLogIncludedHouseWork,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) {
      return _EditWorkLogDialog(
        workLogIncludedHouseWork: workLogIncludedHouseWork,
      );
    },
  );
}

class _EditWorkLogDialog extends StatefulWidget {
  const _EditWorkLogDialog({
    required this.workLogIncludedHouseWork,
  });

  final WorkLogIncludedHouseWork workLogIncludedHouseWork;

  @override
  State<_EditWorkLogDialog> createState() => _EditWorkLogDialogState();
}

class _EditWorkLogDialogState extends State<_EditWorkLogDialog> {
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
          HouseWorkIcon(icon: houseWork.icon, size: HouseWorkIconSize.small),
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
              DateFormat('yyyy/MM/dd (E)').format(_selectedDateTime),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedDateTime),
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

    if (picked == null) {
      return;
    }

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

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (picked == null) {
      return;
    }

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
