import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            child: Icon(Icons.person, size: 40),
          ),
          SizedBox(height: 12),
          Text(
            'Phạm Văn Hưng (Trưởng nhóm)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${AppConstants.groupName} - Lớp ${AppConstants.classCode}',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
