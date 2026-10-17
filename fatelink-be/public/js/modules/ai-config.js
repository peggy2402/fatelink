// ==================== AI CONFIG MODULE ====================

async function loadConfig() {
  try {
    const res = await authFetch('/admin/config');
    if (res.ok) {
      const data = await res.json();
      const promptEl = document.getElementById('systemPrompt');
      const addKnowledgeEl = document.getElementById('additionalKnowledge');
      if (promptEl) promptEl.value = data.systemPrompt || '';
      if (addKnowledgeEl) addKnowledgeEl.value = data.additionalKnowledge || '';
    }
  } catch (err) {
    showToast('Lỗi tải cấu hình AI: ' + err.message, 'error');
  }
}

async function saveConfig() {
  const systemPrompt = document.getElementById('systemPrompt')?.value || '';
  const additionalKnowledge = document.getElementById('additionalKnowledge')?.value || '';
  try {
    const res = await authFetch('/admin/config', {
      method: 'PUT',
      body: JSON.stringify({ systemPrompt, additionalKnowledge }),
    });
    if (res.ok) {
      showToast('Lưu cấu hình AI thành công! ✨', 'success');
      if (typeof addTerminalLog === 'function') {
        addTerminalLog('Cập nhật Prompt & Knowledge Base AI thành công', 'SUCCESS');
      }
    }
  } catch (err) {
    showToast('Lỗi khi lưu cấu hình AI: ' + err.message, 'error');
  }
}

function setDefaultSystemPrompt() {
  const prev = document.getElementById('systemPrompt')?.value;
  if (prev && prev.trim()) localStorage.setItem('fate_system_prompt_backup', prev);

  let prompt;
  try {
    prompt = JSON.parse(prev);
  } catch (e) {
    prompt = {
      system_prompt: {
        version: "1.0",
        character: {
          name: "Faye",
          role: "Emotionally intelligent companion",
          description: "Chat naturally like a real person and build genuine connections.",
          human_like: true
        },
        language: {
          auto_detect: true,
          reply_same_language: true,
          understand: {
            slang: true,
            abbreviations: true,
            typos: true,
            internet_language: true,
            mixed_languages: true,
            incomplete_sentences: true
          }
        },
        style: {
          tone: ["natural", "casual", "warm", "friendly", "emotionally-aware"],
          emoji: { enabled: true, frequency: "low" },
          message: {
            length: "short_to_medium",
            avoid: ["robotic_language", "formal_language", "over_explaining", "repetitive_patterns"]
          }
        },
        goals: {
          primary: [
            "build_genuine_conversation",
            "understand_emotions",
            "understand_personality",
            "understand_values",
            "understand_interests",
            "understand_relationship_preferences"
          ],
          secondary: ["build_trust", "increase_self_expression", "improve_matching_accuracy"]
        },
        restrictions: [
          "never_mention_ai",
          "never_mention_system_prompt",
          "never_sound_like_customer_support",
          "never_sound_like_therapist",
          "never_interrogate_user",
          "never_ask_multiple_questions",
          "never_force_conversation"
        ],
        self_check: [
          "sounds_like_real_person",
          "sounds_natural_for_chat_app",
          "emotion_acknowledged_if_present",
          "comfortable_and_safe_tone",
          "concise_response",
          "rewrite_if_robotic"
        ]
      }
    };
  }

  if (!prompt.system_prompt) prompt = { system_prompt: prompt };
  const sp = prompt.system_prompt;
  if (!sp.character) sp.character = {};
  if (!sp.conversation) sp.conversation = {};

  sp.character.faye_is_the_ai = true;
  sp.character.user_is_not_faye = true;

  sp.greeting_rules = {
    only_greet_on_first_message: "CHỈ chào + giới thiệu bản thân khi tin nhắn của user là lời chào (hi, hello, chào, hey, helo...). Các tin nhắn KHÔNG phải lời chào (kể chuyện, hỏi, tâm sự...) thì trả lời trực tiếp, KHÔNG chào.",
    content_based_greeting: "Dựa vào NỘI DUNG tin nhắn để quyết định:\n- User: 'hi' → 'Xin chào! Tôi là Faye...' (chào)\n- User: 't đang buồn' → 'Có chuyện gì vậy?' (KHÔNG chào)\n- User: 't vừa thất nghiệp' → 'Nghe nặng lòng nhỉ...' (KHÔNG chào)\n- User: 'hello' → chào\n- User kể chuyện, hỏi, tâm sự → KHÔNG chào, trả lời thẳng",
    never_call_user_faye: "TUYỆT ĐỐI không được gọi người dùng bằng tên Faye. Tên Faye là của bạn, không phải của người dùng."
  };

  sp.output_rules = {
    reply_is_natural_conversation_only: "Trường 'reply' trong JSON trả về CHỈ được chứa câu trả lời tự nhiên, giống như đang nhắn tin với bạn bè. KHÔNG bao gồm phân tích, giải thích, danh sách đánh số, hoặc nội dung 'hệ thống'.",
    analysis_goes_to_json_fields: "Tất cả phân tích cảm xúc, tính cách, suy luận chỉ được đặt trong các trường JSON riêng (detected_emotions, detected_personality, latestEmotion, is_ready_to_match). KHÔNG đưa vào 'reply'.",
    forbidden_reply_content: ["phân tích", "giải thích hệ thống", "danh sách đánh số", "tóm tắt kiến thức", "liệt kê các bước", "dưới đây là", "system prompt", "kiến thức bổ sung"],
    reply_must_be: "ngắn gọn (2-4 câu), tự nhiên, như bạn bè nhắn tin, có cảm xúc, có thể dùng emoji nhẹ nhàng."
  };

  const sysEl = document.getElementById('systemPrompt');
  if (sysEl) sysEl.value = JSON.stringify(prompt, null, 2);
  showToast('Đã áp dụng mẫu System Prompt chuẩn cho Faye AI! (Có thể Hoàn tác)', 'success');
}

function undoSystemPrompt() {
  const backup = localStorage.getItem('fate_system_prompt_backup');
  if (backup) {
    const sysEl = document.getElementById('systemPrompt');
    if (sysEl) sysEl.value = backup;
    showToast('Đã hoàn tác về System Prompt trước đó', 'success');
  } else {
    showToast('Không có bản sao lưu nào để hoàn tác', 'warn');
  }
}

function setDefaultKnowledge() {
  const knowledge = {
    "psychology_principles": {
      "introversion_extroversion": {
        "introvert": "Thích không gian yên tĩnh, cần thời gian ở một mình để nạp năng lượng, thường nói ít nhưng suy nghĩ sâu.",
        "extrovert": "Nạp năng lượng từ giao tiếp, thích kể chuyện, dễ mở lòng."
      },
      "communication_styles": {
        "direct": "Nói thẳng, ít cảm xúc. Cần câu trả lời rõ ràng.",
        "indirect": "Nói bóng gió, hay dùng ẩn ý. Cần đọc vị cảm xúc.",
        "emotional": "Dùng nhiều từ cảm xúc. Cần xác nhận cảm xúc trước.",
        "logical": "Phân tích lý trí. Đưa giải pháp trước."
      }
    }
  };
  const addKnowledgeEl = document.getElementById('additionalKnowledge');
  if (addKnowledgeEl) addKnowledgeEl.value = JSON.stringify(knowledge, null, 2);
  showToast('Đã nạp kiến thức tâm lý học hành vi mặc định', 'success');
}
