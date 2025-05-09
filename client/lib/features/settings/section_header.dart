import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final safeAreaLeftPadding = MediaQuery.of(context).padding.left;
    final leftPadding = safeAreaLeftPadding > 0 ? safeAreaLeftPadding : 16.0;
    final safeAreaRightPadding = MediaQuery.of(context).padding.right;
    final rightPadding = safeAreaRightPadding > 0 ? safeAreaRightPadding : 16.0;

    return Padding(
      padding: EdgeInsets.only(
        left: leftPadding,
        top: 16,
        right: rightPadding,
        bottom: 16,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
