import 'package:flutter/material.dart';

class FavoriteFilterButton extends StatelessWidget {
  final bool showOnlyFavorites;
  final Function() onToggle;

  const FavoriteFilterButton({
    super.key,
    required this.showOnlyFavorites,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
        color: showOnlyFavorites ? Colors.red : null,
      ),
      onPressed: onToggle,
      tooltip: showOnlyFavorites ? '显示所有食品' : '只显示收藏',
    );
  }
}
