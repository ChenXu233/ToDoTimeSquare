/// AI 服务抽象接口
/// 提供统一的 AI API 调用方式，支持 Claude/GPT 等多种实现
abstract class AIProvider {
  /// 发送提示词并获取完成结果
  /// 返回 AI 生成的文本，失败时返回 null
  Future<String?> complete(String prompt);

  /// 发送提示词并获取流式结果（可选实现）
  /// 默认实现调用 complete 并包装为单次返回
  Stream<String> completeStream(String prompt) async* {
    final result = await complete(prompt);
    if (result != null) {
      yield result;
    }
  }
}
