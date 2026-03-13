import 'dart:async';

import 'package:flutter/material.dart';

class TaskExpiryBadge extends StatefulWidget {
  const TaskExpiryBadge({
    required this.expiresAt,
    super.key,
  });

  final DateTime? expiresAt;

  @override
  State<TaskExpiryBadge> createState() => _TaskExpiryBadgeState();
}

class _TaskExpiryBadgeState extends State<TaskExpiryBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void didUpdateWidget(covariant TaskExpiryBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _startTicker();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expiresAt = widget.expiresAt;
    if (expiresAt == null) {
      return const SizedBox.shrink();
    }

    final remaining = expiresAt.difference(DateTime.now());
    final isExpired = remaining.isNegative || remaining.inSeconds <= 0;
    final isCritical = !isExpired && remaining.inMinutes < 2;
    final isUrgent = !isExpired && remaining.inMinutes < 10;
    final accent = isExpired
        ? Theme.of(context).colorScheme.error
        : isCritical
            ? const Color(0xFFB91C1C)
            : isUrgent
                ? const Color(0xFFD97706)
                : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 6),
          Text(
            isExpired ? 'Expired' : 'Expires in ${_formatDuration(remaining)}',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _startTicker() {
    _timer?.cancel();
    if (widget.expiresAt == null) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _formatDuration(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    final seconds = safe.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '${safe.inMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}