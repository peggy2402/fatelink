import type { IAiProvider } from '@shared/contracts/ai-provider.service';
import type { AiModelCatalogRepository } from '@contexts/admin/domain/repositories/ai-model-catalog.repository';

export interface SuggestRepliesInput {
  partnerName: string;
  lastPartnerMessage?: string;
  recentContext?: string[];
}

export class SuggestRepliesUseCase {
  constructor(
    private readonly providers: IAiProvider[],
    private readonly aiModelCatalogRepository: AiModelCatalogRepository,
  ) {}

  async execute(input: SuggestRepliesInput): Promise<string[]> {
    const prompt = this.buildPrompt(input);

    try {
      const activeModels = (
        (await this.aiModelCatalogRepository.getAiModels?.()) || []
      )
        .filter((model) => model.isEnabled)
        .sort((a, b) => a.priority - b.priority);

      // 1. Thử qua danh mục các Model AI đang kích hoạt (Groq, Gemini, OpenAI,...)
      for (const model of activeModels) {
        const provider = this.providers.find(
          (p) =>
            p.providerName.toLowerCase() === model.providerName.toLowerCase(),
        );
        if (!provider) continue;

        try {
          const res = await provider.generateContent(prompt, model.modelId);
          const parsed = this.parseSuggestions(res.rawText);
          if (parsed.length > 0) {
            return parsed;
          }
        } catch (_) {}
      }

      // 2. Fallback trực tiếp qua danh sách Providers sẵn có
      for (const provider of this.providers) {
        try {
          const res = await provider.generateContent(prompt);
          const parsed = this.parseSuggestions(res.rawText);
          if (parsed.length > 0) {
            return parsed;
          }
        } catch (_) {}
      }
    } catch (_) {}

    // 3. Fallback câu trả lời thông minh theo ngữ cảnh nếu tất cả AI ngoại tuyến
    return this.getFallbackReplies(input.partnerName, input.lastPartnerMessage);
  }

  private buildPrompt(input: SuggestRepliesInput): string {
    const partner = input.partnerName.trim() || 'Bạn ấy';
    const lastMsg = input.lastPartnerMessage?.trim();

    if (lastMsg) {
      return `Bạn là Faye AI Wingman - trợ lý gợi ý câu trả lời thông minh, tinh tế và cực kỳ cuốn hút trong ứng dụng hẹn hò & kết nối tâm hồn FateLink.
Đối phương là: "${partner}".
Tin nhắn gần nhất đối phương vừa nhắn cho người dùng: "${lastMsg}"
${input.recentContext && input.recentContext.length > 0 ? `Ngữ cảnh các câu trước: ${input.recentContext.join(' -> ')}` : ''}

Nhiệm vụ: Hãy đóng vai người dùng và nghĩ ra đúng 4 câu TRẢ LỜI lại tin nhắn trên của "${partner}".
Yêu cầu bắt buộc:
1. ĐÂY PHẢI LÀ CÂU TRẢ LỜI tin nhắn của đối phương (ví dụ nếu họ than mệt -> an ủi/hỏi thăm; nếu họ hỏi cơm -> trả lời ăn gì rồi hỏi lại; nếu họ khen -> khiêm tốn đáp lại duyên dáng; nếu họ rủ rê -> nhiệt tình hưởng ứng). KHÔNG ĐƯỢC đặt câu hỏi lạc đề hoặc câu mở đầu vu vơ!
2. Mỗi câu mang một sắc thái tâm lý khác nhau:
   - Câu 1: Quan tâm ấm áp, đồng cảm, ngọt ngào.
   - Câu 2: Dí dỏm, thông minh, trêu đùa nhẹ nhàng.
   - Câu 3: Gợi mở sâu lắng, kéo dài câu chuyện tự nhiên.
   - Câu 4: Tự nhiên, ngắn gọn, phong cách trẻ trung hiện đại.
3. Độ dài: 10 - 25 từ mỗi câu. Xưng hô tự nhiên ("cậu - mình", "cậu - tớ" hoặc linh hoạt).
4. ĐỊNH DẠNG TRẢ VỀ: BẮT BUỘC chỉ trả về DUY NHẤT một chuỗi JSON hợp lệ gồm một mảng 4 chuỗi, không có bất kỳ lời dẫn hay ký tự markdown nào bên ngoài. Ví dụ:
["câu trả lời 1", "câu trả lời 2", "câu trả lời 3", "câu trả lời 4"]`;
    }

    return `Bạn là Faye AI Wingman - trợ lý hẹn hò và kết nối tâm hồn cho FateLink.
Người dùng vừa kết nối với bạn chat tên là "${partner}" và cần câu mở lời (icebreaker).
Nhiệm vụ: Hãy tạo đúng 4 câu mở lời tự nhiên, tinh tế, gây ấn tượng tốt đẹp và dễ thương nhất để người dùng bắt chuyện với "${partner}".
Độ dài: 10 - 25 từ mỗi câu.
ĐỊNH DẠNG TRẢ VỀ: BẮT BUỘC chỉ trả về DUY NHẤT một chuỗi JSON hợp lệ gồm một mảng 4 chuỗi:
["câu 1", "câu 2", "câu 3", "câu 4"]`;
  }

  private parseSuggestions(rawText: string): string[] {
    if (!rawText) return [];
    try {
      const startIdx = rawText.indexOf('[');
      const endIdx = rawText.lastIndexOf(']');
      if (startIdx !== -1 && endIdx !== -1 && endIdx > startIdx) {
        const jsonStr = rawText.substring(startIdx, endIdx + 1);
        const parsed = JSON.parse(jsonStr);
        if (Array.isArray(parsed)) {
          const cleaned = parsed
            .map((item) => (typeof item === 'string' ? item.trim() : ''))
            .filter((item) => item.length > 0);
          if (cleaned.length >= 2) {
            return cleaned.slice(0, 4);
          }
        }
      }
    } catch (_) {}

    const lines = rawText
      .split('\n')
      .map((line) =>
        line
          .replace(/^[\d\.\-\*\•\s"\']+/, '')
          .replace(/["\',]+$/, '')
          .trim(),
      )
      .filter(
        (line) =>
          line.length >= 5 && !line.startsWith('[') && !line.startsWith(']'),
      );

    return lines.slice(0, 4);
  }

  private getFallbackReplies(
    partnerName: string,
    lastMessage?: string,
  ): string[] {
    const partner = partnerName || 'cậu';
    if (!lastMessage) {
      return [
        `Chào ${partner}, hôm nay của cậu có điều gì làm cậu mỉm cười không? ✨`,
        `Faye bảo tần số của hai đứa mình hợp nhau lắm, rất vui được trò chuyện cùng ${partner}!`,
        `Hi ${partner}, cậu có đang nghe bài hát nào hay ho không share cho mình với nhé?`,
        `Chào cậu nè, định mệnh đưa chúng ta gặp nhau ở FateLink hôm nay rồi đó 💫`,
      ];
    }

    const lower = lastMessage.toLowerCase();
    if (
      lower.includes('mệt') ||
      lower.includes('oải') ||
      lower.includes('stress')
    ) {
      return [
        `Thương cậu thế, đã về nhà nghỉ ngơi chưa hay vẫn đang cày cuốc vậy?`,
        `Làm cốc nước ấm rồi ngả lưng chút đi nè, cần người nghe cậu than thở thì có mình đây nhé!`,
        `Hôm nay việc nhiều lắm hả? Để mình truyền chút năng lượng tích cực cho cậu nha ✨`,
        `Đi làm/đi học vất vả rồi, tối nay nhớ tự thưởng cho mình món gì ngon ngon nhé!`,
      ];
    }

    if (
      lower.includes('cơm') ||
      lower.includes('ăn') ||
      lower.includes('đói')
    ) {
      return [
        `Mình vừa ăn xong rồi nè, còn cậu đã nạp năng lượng chưa đó?`,
        `Hôm nay cậu ăn món gì ngon thế? Gợi ý cho mình với, đang chưa biết ăn gì đây!`,
        `Bận mấy cũng phải ăn đúng giờ nha, dạ dày biểu tình là mình phạt đó!`,
        `Nhắc đến ăn làm mình cũng thấy đói bụng luôn rồi nè 🍲`,
      ];
    }

    return [
      `Nghe cậu kể thú vị ghê, kể thêm cho mình nghe đoạn sau với nào!`,
      `Cậu nói chuẩn gu mình luôn đấy, tự nhiên thấy nói chuyện với cậu hợp phết ✨`,
      `Haha thế á, cậu làm mình tò mò muốn biết nhiều hơn về cậu rồi đấy nhé!`,
      `Công nhận luôn! Mà bình thường cậu cũng hay để ý mấy điều tinh tế thế này hả?`,
    ];
  }
}
