import 'dart:convert';

class ChatMessage {
  final String id;
  final String text;
  final bool isSentByMe;
  final DateTime timestamp;
  final String? reaction;
  final String? replyToText;
  final String? replyToSender;
  final bool isRevoked;
  final List<String> imageUrls;
  final String messageType; // 'text', 'imageStack', 'voice', 'location', 'revoked'

  // Các trường cấu trúc cho Tin nhắn thoại (Voice Note) chuẩn Telegram
  final String? mediaUrl;
  final int? durationMs;
  final List<int>? waveform; // Mảng 40 số từ 0 - 31 lấy từ biên độ thực tế
  final bool isSending; // Đang upload / xử lý nền
  final bool isSendError; // Upload thất bại, chạm để thử lại
  final String? localFilePath; // Lưu tệp cục bộ tạm để retry

  ChatMessage({
    String? id,
    required this.text,
    required this.isSentByMe,
    required this.timestamp,
    this.reaction,
    this.replyToText,
    this.replyToSender,
    this.isRevoked = false,
    this.imageUrls = const [],
    this.messageType = 'text',
    this.mediaUrl,
    this.durationMs,
    this.waveform,
    this.isSending = false,
    this.isSendError = false,
    this.localFilePath,
  }) : id = id ?? '${timestamp.millisecondsSinceEpoch}_${text.hashCode}';

  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final text = json['text']?.toString() ?? '';
    final imageUrls = (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [];
    String messageType = json['messageType']?.toString() ??
        (imageUrls.length > 1 ? 'imageStack' : (text.startsWith('[Hình ảnh]') ? 'image' : 'text'));

    String? mediaUrl = json['mediaUrl']?.toString();
    int? durationMs = json['durationMs'] != null ? int.tryParse(json['durationMs'].toString()) : null;
    List<int>? waveform;
    if (json['waveform'] is List) {
      waveform = (json['waveform'] as List).map((e) => (int.tryParse(e.toString()) ?? 8).clamp(0, 31)).toList();
    }

    if (mediaUrl != null && mediaUrl.isNotEmpty && (messageType == 'text' || messageType.isEmpty)) {
      messageType = 'voice';
    } else if (imageUrls.isNotEmpty && (messageType == 'text' || messageType.isEmpty)) {
      messageType = imageUrls.length > 1 ? 'imageStack' : 'image';
    }

    if (text.startsWith('{') && text.endsWith('}')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map && decoded['type'] == 'voice') {
          messageType = 'voice';
          mediaUrl ??= decoded['url']?.toString();
          durationMs ??= decoded['durationMs'] != null ? int.tryParse(decoded['durationMs'].toString()) : null;
          if (decoded['waveform'] is List) {
            waveform ??= (decoded['waveform'] as List).map((e) => (int.tryParse(e.toString()) ?? 8).clamp(0, 31)).toList();
          }
        }
      } catch (_) {}
    }

    final senderId = json['senderId']?.toString();
    final isSentByMe = json['isSentByMe'] == true || (currentUserId != null && senderId == currentUserId);

    return ChatMessage(
      id: json['id']?.toString(),
      text: text,
      isSentByMe: isSentByMe,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? json['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      reaction: json['reaction']?.toString(),
      replyToText: json['replyToText']?.toString(),
      replyToSender: json['replyToSender']?.toString(),
      isRevoked: json['isRevoked'] == true,
      imageUrls: imageUrls,
      messageType: messageType,
      mediaUrl: mediaUrl,
      durationMs: durationMs,
      waveform: waveform,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isSentByMe,
    DateTime? timestamp,
    String? reaction,
    String? replyToText,
    String? replyToSender,
    bool? isRevoked,
    List<String>? imageUrls,
    String? messageType,
    String? mediaUrl,
    int? durationMs,
    List<int>? waveform,
    bool? isSending,
    bool? isSendError,
    String? localFilePath,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isSentByMe: isSentByMe ?? this.isSentByMe,
      timestamp: timestamp ?? this.timestamp,
      reaction: reaction ?? this.reaction,
      replyToText: replyToText ?? this.replyToText,
      replyToSender: replyToSender ?? this.replyToSender,
      isRevoked: isRevoked ?? this.isRevoked,
      imageUrls: imageUrls ?? this.imageUrls,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      durationMs: durationMs ?? this.durationMs,
      waveform: waveform ?? this.waveform,
      isSending: isSending ?? this.isSending,
      isSendError: isSendError ?? this.isSendError,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }

  /// Nhận diện tin nhắn thoại
  bool get isVoice {
    if (messageType == 'voice') return true;
    if (text.startsWith('🎙️')) return true;
    if (text.startsWith('{"type":"voice"') || text.contains('"type":"voice"')) return true;
    if (text.contains('[voice:')) return true;
    return false;
  }

  /// Lấy URL phát âm thanh thực tế (hỗ trợ cả schema JSON mới và format chuỗi cũ)
  String? get effectiveMediaUrl {
    if (mediaUrl != null && mediaUrl!.isNotEmpty) return mediaUrl;

    // 1. Thử parse JSON payload: {"type":"voice","url":"https://...","durationMs":...}
    try {
      if (text.startsWith('{') && text.endsWith('}')) {
        final decoded = jsonDecode(text);
        if (decoded is Map && decoded['url'] != null) {
          return decoded['url'].toString();
        }
      }
    } catch (_) {}

    // 2. Thử regex chuỗi format cũ: 🎙️ [voice:URL|duration:X|time:MM:SS]
    final reg = RegExp(r'\[voice:(https?://[^\|\]]+)');
    final match = reg.firstMatch(text);
    if (match != null) return match.group(1);

    // 3. Fallback tìm URL trực tiếp
    final regDirect = RegExp(r'(https?://[^\s]+\.(m4a|aac|mp3|ogg|wav))');
    final matchDirect = regDirect.firstMatch(text);
    if (matchDirect != null) return matchDirect.group(1);

    // 4. Nếu là file local đang gửi tạm
    if (localFilePath != null && localFilePath!.isNotEmpty) {
      return localFilePath;
    }

    return null;
  }

  /// Lấy thời lượng âm thanh tính bằng mili-giây
  int get effectiveDurationMs {
    if (durationMs != null && durationMs! > 0) return durationMs!;

    // 1. Thử parse từ JSON
    try {
      if (text.startsWith('{') && text.endsWith('}')) {
        final decoded = jsonDecode(text);
        if (decoded is Map && decoded['durationMs'] != null) {
          final ms = int.tryParse(decoded['durationMs'].toString());
          if (ms != null && ms > 0) return ms;
        }
      }
    } catch (_) {}

    // 2. Thử parse từ chuỗi cũ duration:X (giây) hoặc MM:SS
    try {
      final regDur = RegExp(r'duration:(\d+)');
      final matchDur = regDur.firstMatch(text);
      if (matchDur != null) {
        final sec = int.tryParse(matchDur.group(1) ?? '3') ?? 3;
        return sec * 1000;
      }

      final regTime = RegExp(r'(\d+):(\d+)');
      final matchTime = regTime.firstMatch(text);
      if (matchTime != null) {
        final m = int.tryParse(matchTime.group(1) ?? '0') ?? 0;
        final s = int.tryParse(matchTime.group(2) ?? '3') ?? 3;
        return (m * 60 + s) * 1000;
      }
    } catch (_) {}

    return 3000; // Mặc định 3s
  }

  /// Lấy mảng waveform 40 cột (giá trị từ 0 đến 31)
  List<int> get effectiveWaveform {
    if (waveform != null && waveform!.isNotEmpty) {
      // Chuẩn hóa đúng 40 phần tử
      if (waveform!.length == 40) return waveform!;
      if (waveform!.length > 40) return waveform!.sublist(0, 40);
      return List<int>.generate(40, (i) => i < waveform!.length ? waveform![i] : 8);
    }

    // 1. Thử parse từ JSON
    try {
      if (text.startsWith('{') && text.endsWith('}')) {
        final decoded = jsonDecode(text);
        if (decoded is Map && decoded['waveform'] is List) {
          final list = (decoded['waveform'] as List).map((e) => (int.tryParse(e.toString()) ?? 6).clamp(0, 31)).toList();
          if (list.isNotEmpty) {
            if (list.length == 40) return list;
            if (list.length > 40) return list.sublist(0, 40);
            return List<int>.generate(40, (i) => i < list.length ? list[i] : 8);
          }
        }
      }
    } catch (_) {}

    // 2. Waveform tĩnh mặc định đẹp mắt cho các tin nhắn cũ
    final seed = id.hashCode.abs();
    return List<int>.generate(40, (index) {
      final val = ((seed + index * 17) % 24) + 4;
      return val.clamp(3, 31);
    });
  }

  /// Tạo chuỗi JSON payload chuẩn để gửi qua Socket / HTTP
  String toVoicePayload() {
    return jsonEncode({
      'type': 'voice',
      'url': mediaUrl ?? '',
      'durationMs': durationMs ?? 3000,
      'waveform': effectiveWaveform,
    });
  }
}