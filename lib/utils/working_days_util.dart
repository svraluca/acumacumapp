import 'package:flutter/material.dart';

class WorkingDaysUtil {
  static Widget buildWorkingDays(Map<String, dynamic>? workingDays) {
    final List<String> daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: daysOfWeek.map((day) {
        bool isWorkingDay = workingDays?[day.toLowerCase()] ?? false;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isWorkingDay ? Colors.green : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                color: isWorkingDay ? Colors.white : Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
