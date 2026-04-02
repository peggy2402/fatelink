import { Injectable, Logger } from '@nestjs/common';
import { IAiProvider, AiProviderResponse } from './ai-provider.interface';
import * as path from 'path';

const API_TIMEOUT = 60000; // Local model cần thời gian chờ lâu hơn (60s)

@Injectable()
export class LlamaProvider implements IAiProvider {
  readonly providerName = 'LlamaLocal';
  private readonly logger = new Logger(LlamaProvider.name);
  private session: any; 
  private isModelLoaded = false;

  constructor() {
    this.initModel();
  }

  private async initModel() {
    try {
      // Import động (dynamic import) để tương thích với node-llama-cpp
      const { getLlama, LlamaChatSession } = await import('node-llama-cpp');
      
      // Yêu cầu: Bạn phải tải file model (VD: llama-3-8b.gguf) vào thư mục /models
      const modelPath = path.join(process.cwd(), 'models', 'Meta-Llama-3-8B.Q4_K_M.gguf');
      
      this.logger.log('Đang nạp Llama model vào RAM, quá trình này có thể mất vài chục giây...');
      const llama = await getLlama();
      const model = await llama.loadModel({ modelPath });
      const context = await model.createContext();
      this.session = new LlamaChatSession({ contextSequence: context.getSequence() });

      this.isModelLoaded = true;
      this.logger.log('Đã tải thành công Llama Local Model vào RAM.');
    } catch (error: any) {
      this.logger.error(`Lỗi load Llama model: ${error.message}. (Bạn đã tải file model .gguf chưa?)`);
    }
  }

  async generateContent(prompt: string): Promise<AiProviderResponse> {
    if (!this.isModelLoaded) throw new Error('Llama model chưa sẵn sàng hoặc đang khởi tạo.');

    try {
      const timeoutPromise = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error(`Quá thời gian chờ ${API_TIMEOUT}ms.`)), API_TIMEOUT)
      );

      // session.prompt tự động quản lý lịch sử hội thoại và sinh ra text
      const generatePromise = this.session.prompt(prompt);

      const rawText = await Promise.race([generatePromise, timeoutPromise]) as string;
      return { rawText };
    } catch (error: any) {
      throw error;
    }
  }
}