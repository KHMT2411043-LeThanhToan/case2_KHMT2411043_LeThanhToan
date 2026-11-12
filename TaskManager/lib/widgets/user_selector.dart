
import 'package:flutter/material.dart';

class UserSelector extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final bool isSearching;
  final List<Map<String, dynamic>> searchResults;
  final ValueChanged<String> onSearch;
  final ValueChanged<Map<String, dynamic>> onUserSelected;

  const UserSelector({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    required this.isSearching,
    required this.searchResults,
    required this.onSearch,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(prefixIcon),
            suffixIcon: isSearching
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
                : null,
          ),
          onChanged: onSearch,
        ),
        if (searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: searchResults.map((user) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(prefixIcon),
                  ),
                  title: Text(
                    user['fullName']?.toString() ?? 'Không có tên',
                  ),
                  subtitle: Text(
                    user['email']?.toString() ?? '',
                  ),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () => onUserSelected(user),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
