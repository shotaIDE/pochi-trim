import 'package:flutter/material.dart';
import 'package:pochi_trim/data/model/house_work.dart';

enum _ModalAction { delete }

class HouseWorkItem extends StatefulWidget {
  const HouseWorkItem({
    super.key,
    required this.houseWork,
    required this.onCompleteTap,
    required this.onDelete,
  });

  final HouseWork houseWork;
  final void Function(HouseWork) onCompleteTap;
  final void Function(HouseWork) onDelete;

  @override
  State<HouseWorkItem> createState() => _HouseWorkItemState();
}

class _HouseWorkItemState extends State<HouseWorkItem> {
  var _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    final doCompleteIcon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _isCompleting
          ? Icon(
              Icons.check_circle,
              key: const ValueKey('check_circle'),
              color: Theme.of(context).colorScheme.primary,
            )
          : Icon(
              Icons.check_circle_outline,
              key: const ValueKey('check_circle_outline'),
              color: Theme.of(context).colorScheme.onSurface,
            ),
    );
    final houseWorkIcon = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      width: 40,
      height: 40,
      child: Text(
        widget.houseWork.icon,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
    final houseWorkTitleText = Text(
      widget.houseWork.title,
      style: Theme.of(context).textTheme.titleMedium,
    );
    final item = GestureDetector(
      onTap: _onTap,
      onLongPress: _onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            doCompleteIcon,
            const SizedBox(width: 16),
            houseWorkIcon,
            const SizedBox(width: 12),
            Expanded(child: houseWorkTitleText),
          ],
        ),
      ),
    );

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: item,
    );
  }

  void _onTap() {
    setState(() {
      _isCompleting = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    });

    widget.onCompleteTap(widget.houseWork);
  }

  Future<void> _onLongPress() async {
    final action = await showModalBottomSheet<_ModalAction>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('削除する'),
                onTap: () => Navigator.of(context).pop(_ModalAction.delete),
              ),
            ],
          ),
        );
      },
      clipBehavior: Clip.antiAlias,
    );

    if (action != _ModalAction.delete) {
      return;
    }

    widget.onDelete(widget.houseWork);
  }
}
