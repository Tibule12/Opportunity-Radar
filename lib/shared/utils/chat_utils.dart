String taskChatId({
  required String taskId,
  required String customerId,
  required String workerId,
}) {
  return '${taskId}_${customerId}_$workerId';
}
