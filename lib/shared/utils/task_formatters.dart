String taskCategoryLabel(String value) {
  switch (value) {
    case 'delivery':
      return 'Delivery';
    case 'transport':
      return 'Transport';
    case 'errands':
      return 'Errands';
    case 'moving_help':
      return 'Moving Help';
    default:
      return 'Other';
  }
}

String taskCurrencyLabel(String currency, double amount) {
  if (currency == 'ZAR') {
    return 'R${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }

  return '$currency ${amount.toStringAsFixed(2)}';
}

String taskRelativeTimeLabel(DateTime? createdAt) {
  if (createdAt == null) {
    return 'Posted just now';
  }

  final difference = DateTime.now().difference(createdAt);
  if (difference.inSeconds < 60) {
    return 'Posted ${difference.inSeconds.clamp(1, 59)} seconds ago';
  }
  if (difference.inMinutes < 60) {
    return 'Posted ${difference.inMinutes} minutes ago';
  }
  if (difference.inHours < 24) {
    return 'Posted ${difference.inHours} hours ago';
  }

  return 'Posted ${difference.inDays} days ago';
}

String taskExpiryLabel(DateTime? expiresAt) {
  if (expiresAt == null) {
    return 'No expiry set';
  }

  final difference = expiresAt.difference(DateTime.now());
  if (difference.isNegative) {
    return 'Expired';
  }
  if (difference.inMinutes < 60) {
    return 'In ${difference.inMinutes} minutes';
  }
  if (difference.inHours < 24) {
    return 'In ${difference.inHours} hours';
  }

  return 'In ${difference.inDays} days';
}
