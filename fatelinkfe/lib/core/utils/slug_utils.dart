import 'dart:math' as math;

class SlugUtils {
  /// Bảng chuyển đổi tiếng Việt có dấu sang không dấu
  static const Map<String, String> _vietnameseMap = {
    'a': 'áàảãạăắằẳẵặâấầẩẫậ',
    'A': 'ÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬ',
    'd': 'đ',
    'D': 'Đ',
    'e': 'éèẻẽẹêếềểễệ',
    'E': 'ÉÈẺẼẸÊẾỀỂỄỆ',
    'i': 'íìỉĩị',
    'I': 'ÍÌỈĨỊ',
    'o': 'óòỏõọôốồổỗộơớờởỡợ',
    'O': 'ÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢ',
    'u': 'úùủũụưứừửữự',
    'U': 'ÚÙỦŨỤƯỨỪỬỮỰ',
    'y': 'ýỳỷỹỵ',
    'Y': 'ÝỲỶỸỴ',
  };

  /// Chuyển đổi chuỗi tiếng Việt thành tiếng Anh không dấu
  static String removeDiacritics(String str) {
    String result = str;
    _vietnameseMap.forEach((nonAccent, accents) {
      for (int i = 0; i < accents.length; i++) {
        result = result.replaceAll(accents[i], nonAccent);
      }
    });
    return result;
  }

  /// Chuẩn hóa handle: 100% tiếng Anh không dấu, chữ thường, không dấu cách, không '/', không ký tự lạ
  /// Ví dụ: "Trần Văn Chiến" -> "tranvanchien"
  static String toCleanHandle(String? input, {String? fallbackSeed}) {
    if (input == null || input.trim().isEmpty) {
      final seed = fallbackSeed ?? '${math.Random().nextInt(900) + 100}';
      return 'user_$seed';
    }

    // 1. Bỏ ký tự '@' ở đầu nếu có
    String text = input.trim();
    if (text.startsWith('@')) {
      text = text.substring(1);
    }

    // 2. Bỏ dấu tiếng Việt
    text = removeDiacritics(text);

    // 3. Chuyển sang chữ thường
    text = text.toLowerCase();

    // 4. Loại bỏ toàn bộ ký tự không phải a-z, 0-9, dấu gạch dưới '_'
    text = text.replaceAll(RegExp(r'[^a-z0-9_]'), '');

    if (text.isEmpty) {
      final seed = fallbackSeed ?? '${math.Random().nextInt(900) + 100}';
      return 'user_$seed';
    }

    return text;
  }

  /// Trả về chuỗi hiển thị có tiền tố @ (ví dụ: "@tranvanchien")
  static String toDisplayHandle(String? input, {String? fallbackSeed}) {
    final clean = toCleanHandle(input, fallbackSeed: fallbackSeed);
    return '@$clean';
  }

  /// Định dạng link chia sẻ chuẩn: https://meyu.com/m/@tranvanchien
  static String buildShareProfileUrl(String? input, {String? fallbackSeed}) {
    final clean = toCleanHandle(input, fallbackSeed: fallbackSeed);
    return 'https://meyu.com/m/@$clean';
  }
}
