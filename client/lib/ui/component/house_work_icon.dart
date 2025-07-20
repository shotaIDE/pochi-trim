import 'package:flutter/material.dart';

enum HouseWorkIconSize {
  small(32),
  medium(40);

  const HouseWorkIconSize(this.value);
  final double value;
}

class HouseWorkIcon extends StatelessWidget {
  const HouseWorkIcon({
    super.key,
    required this.icon,
    this.size = HouseWorkIconSize.medium,
  });

  final String icon;
  final HouseWorkIconSize size;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      width: size.value,
      height: size.value,
      child: Text(
        icon,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}
