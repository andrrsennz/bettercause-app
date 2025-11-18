import 'package:flutter/material.dart';

class AgeSelector extends StatelessWidget {
  final int? selectedAge;
  final ValueChanged<int> onAgeSelected;

  const AgeSelector({
    super.key,
    required this.selectedAge,
    required this.onAgeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListWheelScrollView.useDelegate(
              itemExtent: 50,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                onAgeSelected(index + 13); // Start from age 13
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  final age = index + 13;
                  final isSelected = age == selectedAge;
                  
                  return Center(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE8E5FF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$age',
                        style: TextStyle(
                          fontSize: isSelected ? 32 : 24,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? const Color(0xFF8B7FED)
                              : const Color(0xFF999999),
                        ),
                      ),
                    ),
                  );
                },
                childCount: 88, // Ages 13-100
              ),
            ),
          ),
        ],
      ),
    );
  }
}