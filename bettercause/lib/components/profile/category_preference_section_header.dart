import 'package:flutter/material.dart';

class CategoryPreferenceSectionHeader extends StatelessWidget {
  final String title;
  final bool isFirst;

  const CategoryPreferenceSectionHeader({
    super.key,
    required this.title,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: isFirst ? 0 : 32,
        bottom: 16,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}