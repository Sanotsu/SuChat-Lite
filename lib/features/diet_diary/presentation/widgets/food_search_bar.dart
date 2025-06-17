import 'package:flutter/material.dart';

class FoodSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final Function() onClearSearch;
  final String hintText;
  final bool filled;
  final Color? fillColor;

  const FoodSearchBar({
    super.key,
    this.controller,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    this.hintText = '搜索食品',
    this.filled = false,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: onClearSearch,
                  )
                  : null,
          filled: filled,
          fillColor: fillColor ?? Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: filled ? BorderSide.none : const BorderSide(),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 16.0,
          ),
        ),
        onChanged: onSearchChanged,
      ),
    );
  }
}
