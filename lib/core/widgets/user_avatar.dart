import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double radius;
  final double? fontSize;

  const UserAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.radius = 20,
    this.fontSize,
  });

  Color _getDeterministicColor(String name) {
    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.success,
      AppTheme.warning,
      Colors.teal,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
    ];
    final hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final displayName = name ?? 'Usuario';
    final initials = displayName.isNotEmpty 
        ? displayName.trim().split(' ').take(2).map((e) => e[0].toUpperCase()).join()
        : 'U';
    
    final backgroundColor = _getDeterministicColor(displayName);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: imageUrl == null ? backgroundColor.withValues(alpha: 0.1) : null,
        border: Border.all(
          color: imageUrl == null ? backgroundColor.withValues(alpha: 0.2) : Theme.of(context).dividerColor,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitials(context, initials, backgroundColor),
              )
            : _buildInitials(context, initials, backgroundColor),
      ),
    );
  }

  Widget _buildInitials(BuildContext context, String initials, Color color) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: fontSize ?? (radius * 0.8),
        ),
      ),
    );
  }
}
