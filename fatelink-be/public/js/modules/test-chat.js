// ==================== TEST AI CHAT & FATE INSIGHT MODULE ====================

let _chatMessages = [];
let _modelRatings = JSON.parse(localStorage.getItem('fate_model_ratings') || '{}');

try {
  _chatMessages = JSON.parse(localStorage.getItem('fate_feedback') || '[]');
} catch (e) {
  _chatMessages = [];
}

const FATE_KEYWORDS = {
  emotion: ['vui', 'buồn', 'lo lắng', 'căng thẳng', 'cô đơn', 'tự tin', 'sợ hãi', 'hạnh phúc', 'tức giận', 'thất vọng', 'hy vọng', 'yêu thương', 'ghét', 'nhớ nhung', 'đau khổ', 'mệt mỏi', 'chán nản', 'phấn khích', 'bình yên', 'cô độc', 'tuyệt vọng', 'biết ơn'],
  personality: ['hướng nội', 'hướng ngoại', 'chủ động', 'điềm tĩnh', 'sáng tạo', 'nhút nhát', 'tự ti', 'kiên nhẫn', 'nóng tính', 'dễ gần', 'khó tính', 'thẳng thắn', 'tế nhị', 'hài hước', 'nghiêm túc', 'sôi nổi', 'trầm tính', 'cẩn thận', 'bốc đồng', 'lý trí', 'tình cảm'],
  values: ['gia đình', 'sự nghiệp', 'tự do', 'học tập', 'trách nhiệm', 'tiền bạc', 'tình yêu', 'bạn bè', 'sức khỏe', 'công việc', 'đam mê', 'tín ngưỡng', 'lương thiện', 'trung thực', 'bao dung', 'thành công', 'hạnh phúc gia đình'],
  lifestyle: ['thể thao', 'du lịch', 'thức khuya', 'dậy sớm', 'ẩm thực', 'cà phê', 'sách vở', 'xem phim', 'âm nhạc', 'chơi game', 'nấu ăn', 'chạy bộ', 'yoga', 'thiền định', 'vẽ tranh', 'ca hát', 'dã ngoại', 'câu cá', 'làm vườn'],
  relationship: ['người yêu', 'kết hôn', 'bạn đồng hành', 'tri kỷ', 'tâm sự', 'hẹn hò', 'kết bạn', 'tình cảm', 'chia sẻ', 'đồng điệu', 'tâm hồn', 'cưới hỏi', 'yêu đương', 'quan tâm', 'thấu hiểu', 'chung thủy', 'lãng mạn'],
};

let _fate = {
  scores: { emotion: 0, personality: 0, values: 0, lifestyle: 0, relationship: 0 },
  history: [],
  messages: 0,
};

async function loadModelSelector() {
  const select = document.getElementById('chatModelSelector');
  if (!select) return;
  const currentValue = select.value;
  select.innerHTML = '<option value="">⟳ Theo thứ tự ưu tiên (tự động)</option>';
  try {
    const res = await authFetch('/admin/models');
    if (res.ok) {
      const models = await res.json();
      const hasStatus = Object.keys(_statusCache).length > 0;
      let firstAlive = '';
      models.forEach(m => {
        const isEnabled = m.isEnabled !== false;
        if (!isEnabled) return;
        const cached = _statusCache[m.modelId];
        const isAlive = cached && cached.status === 'SUCCESS';
        if (hasStatus && !isAlive) return;
        const opt = document.createElement('option');
        opt.value = `${m.providerName}|${m.modelId}`;
        const dot = isAlive ? '🟢' : hasStatus ? '🔴' : '❓';
        opt.textContent = `${dot} [${m.providerName}] ${m.displayName} (${m.modelId})`;
        if (isAlive && !firstAlive) firstAlive = opt.value;
        select.appendChild(opt);
      });
      if (currentValue) select.value = currentValue;
      else if (firstAlive) select.value = firstAlive;
      else if (select.options.length > 1) select.selectedIndex = 1;
    }
  } catch (err) {
    console.error('Lỗi tải models cho chat', err);
  }
}

async function sendTestChat(e) {
  if (e) e.preventDefault();
  const input = document.getElementById('chatInput');
  if (!input) return;
  const message = input.value.trim();
  if (!message) return;
  input.value = '';

  const select = document.getElementById('chatModelSelector');
  const selectedVal = select ? select.value : '';
  let modelId = '', providerName = '';
  if (selectedVal) [providerName, modelId] = selectedVal.split('|');

  const chatBox = document.getElementById('chatBox');
  const time = new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
  const modelLabel = select && select.selectedOptions[0]
    ? select.selectedOptions[0].textContent.trim()
    : 'Theo thứ tự ưu tiên';
  const msgId = Date.now();

  const empty = chatBox.querySelector('.text-center.text-gray-400');
  if (empty) empty.remove();

  chatBox.innerHTML += `<div class="flex justify-end mb-3 items-end gap-2">
    <div class="max-w-[70%]">
      <div class="bg-blue-600 text-white px-4 py-2.5 rounded-2xl rounded-br-sm shadow-sm break-words">${message}</div>
      <div class="text-[10px] text-gray-400 text-right mt-0.5 mr-1">${time}</div>
    </div>
    <div class="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center text-sm shrink-0 mb-1">👤</div>
  </div>`;

  chatBox.innerHTML += `<div id="typing-${msgId}" class="flex justify-start mb-3 items-end gap-2">
    <div class="w-8 h-8 rounded-full bg-purple-100 flex items-center justify-center text-sm shrink-0 mb-1">🤖</div>
    <div class="bg-gray-200 text-gray-500 px-4 py-2.5 rounded-2xl rounded-bl-sm animate-pulse text-sm">Faye đang trả lời <small class="text-gray-400 ml-1">(${modelLabel})</small>... </div>
  </div>`;
  chatBox.scrollTop = chatBox.scrollHeight;

  try {
    const body = { message, history: [] };
    _chatMessages.slice(-10).forEach(m => {
      body.history.push({ role: 'user', text: m.userMessage });
      if (m.aiReply) body.history.push({ role: 'assistant', text: m.aiReply });
    });
    if (modelId && providerName) { body.modelId = modelId; body.providerName = providerName; }
    
    const res = await authFetch('/admin/ai-chat', {
      method: 'POST',
      body: JSON.stringify(body),
    });
    
    const typingEl = document.getElementById(`typing-${msgId}`);
    if (typingEl) typingEl.remove();

    const textResponse = await res.text();
    let parsed = null;
    try { parsed = JSON.parse(textResponse); } catch(e) {}

    const replyText = parsed && parsed.reply ? parsed.reply : textResponse;
    const idx = _chatMessages.length;

    _chatMessages.push({
      id: msgId, time, userMessage: message, aiReply: replyText,
      rawResponse: textResponse, parsed,
      modelLabel, modelId, providerName,
      rating: 0, feedback: '',
    });
    localStorage.setItem('fate_feedback', JSON.stringify(_chatMessages));

    analyzeFateInsight(message);
    _fate.history.push(getFateOverall());
    renderFateInsight();

    const starsHtml = renderStars(idx, 0);
    chatBox.innerHTML += `<div id="msg-${msgId}" class="flex justify-start mb-3 items-end gap-2">
      <div class="w-8 h-8 rounded-full bg-purple-100 flex items-center justify-center text-sm shrink-0 mb-1">🤖</div>
      <div class="max-w-[70%]">
        <div class="bg-white border border-gray-200 text-gray-800 px-4 py-2.5 rounded-2xl rounded-bl-sm shadow-sm break-words">${replyText.replace(/\n/g, '<br>')}</div>
        <div class="flex items-center gap-2 mt-0.5 ml-1 flex-wrap">
          <span class="text-[10px] text-gray-400">${time}</span>
          <span class="text-[10px] text-gray-400">·</span>
          <span class="text-[10px] text-gray-400">${modelLabel}</span>
          <button onclick="showDetailModal(${idx})" class="text-[10px] text-blue-500 hover:text-blue-600">Chi tiết</button>
          <span class="ml-auto flex gap-0.5" id="stars-${idx}">${starsHtml}</span>
        </div>
      </div>
    </div>`;
    chatBox.scrollTop = chatBox.scrollHeight;
  } catch (err) {
    const el = document.getElementById(`typing-${msgId}`);
    if (el) el.remove();
    showToast('Lỗi gửi tin nhắn', 'error');
  }
}

function clearChat() {
  const chatBox = document.getElementById('chatBox');
  if (chatBox) chatBox.innerHTML = '<div class="text-center text-gray-400 italic mt-10">Bắt đầu trò chuyện để kiểm tra AI nhé!</div>';
  _chatMessages = [];
  localStorage.setItem('fate_feedback', JSON.stringify(_chatMessages));
  resetFateInsight();
}

function resetFateInsight() {
  _fate = {
    scores: { emotion: 0, personality: 0, values: 0, lifestyle: 0, relationship: 0 },
    history: [],
    messages: 0,
  };
  renderFateInsight();
}

function analyzeFateInsight(message) {
  const lower = message.toLowerCase();
  _fate.messages++;
  let totalHits = 0;
  Object.keys(FATE_KEYWORDS).forEach(dim => {
    const hits = FATE_KEYWORDS[dim].filter(kw => lower.includes(kw)).length;
    if (hits > 0) {
      totalHits += hits;
      const gain = Math.min(12, hits * 4) + (lower.length > 50 ? 3 : 0) + (lower.length > 150 ? 4 : 0);
      _fate.scores[dim] = Math.min(100, _fate.scores[dim] + gain);
    }
  });
  if (totalHits === 0 && lower.length > 20) {
    const dims = Object.keys(_fate.scores);
    const minDim = dims.reduce((a, b) => _fate.scores[a] < _fate.scores[b] ? a : b);
    _fate.scores[minDim] = Math.min(100, _fate.scores[minDim] + 2);
  }
}

function getFateOverall() {
  const s = _fate.scores;
  return Math.round(s.emotion * 0.25 + s.personality * 0.25 + s.values * 0.20 + s.lifestyle * 0.15 + s.relationship * 0.15);
}

function getFateLevel(score) {
  if (score <= 20) return { name: 'Stranger', desc: 'AI mới bắt đầu tìm hiểu bạn.' };
  if (score <= 40) return { name: 'Acquaintance', desc: 'AI đã hiểu một phần tính cách của bạn.' };
  if (score <= 60) return { name: 'Companion', desc: 'AI đã có đủ dữ liệu để bắt đầu đề xuất kết nối.' };
  if (score <= 80) return { name: 'Soul Explorer', desc: 'AI hiểu khá rõ con người thật của bạn.' };
  return { name: 'Deep Insight', desc: 'AI đã xây dựng được hồ sơ cảm xúc và tính cách chi tiết để ghép nối chính xác.' };
}

function getFateColor(score) {
  if (score <= 30) return { hex: '#EF4444', text: 'text-red-500', bar: 'bg-red-500', label: 'Đỏ' };
  if (score <= 60) return { hex: '#F59E0B', text: 'text-amber-500', bar: 'bg-amber-500', label: 'Cam' };
  if (score <= 80) return { hex: '#EAB308', text: 'text-yellow-600', bar: 'bg-yellow-500', label: 'Vàng' };
  return { hex: '#22C55E', text: 'text-green-500', bar: 'bg-green-500', label: 'Xanh' };
}

function renderFateInsight() {
  const panel = document.getElementById('fateInsightPanel');
  if (!panel) return;

  const overall = getFateOverall();
  const miniScore = document.getElementById('miniInsightScore');
  if (miniScore) miniScore.textContent = overall + '%';

  const level = getFateLevel(overall);
  const color = getFateColor(overall);

  const dimMeta = {
    emotion: { label: '❤️ Emotion' },
    personality: { label: '🎭 Personality' },
    values: { label: '🌱 Core Values' },
    lifestyle: { label: '🏃 Lifestyle' },
    relationship: { label: '💕 Relationship' },
  };

  let details = '';
  Object.entries(_fate.scores).forEach(([key, val]) => {
    const c = getFateColor(val);
    details += `
      <div class="mb-2">
        <div class="flex justify-between text-xs mb-0.5"><span class="font-medium text-gray-600">${dimMeta[key].label}</span><span class="${c.text} font-bold">${val}%</span></div>
        <div class="w-full h-2 bg-gray-200 rounded-full overflow-hidden"><div class="h-full rounded-full transition-all duration-700 ${c.bar}" style="width:${val}%"></div></div>
      </div>`;
  });

  panel.innerHTML = `
    <div class="bg-white rounded-xl p-4 shadow-sm border border-gray-200">
      <div class="text-center mb-3">
        <div class="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1">✨ Fate Insight</div>
        <div class="flex items-baseline justify-center gap-1">
          <span class="text-4xl font-black" style="color:${color.hex}">${overall}</span>
          <span class="text-lg font-bold" style="color:#374151">%</span>
        </div>
        <div class="flex items-center justify-center gap-2 mt-1">
          <span class="inline-block w-2 h-2 rounded-full" style="background:${color.hex}"></span>
          <span class="text-sm font-semibold" style="color:${color.hex}">${level.name}</span>
        </div>
        <div class="w-full h-3 bg-gray-200 rounded-full mt-2 overflow-hidden">
          <div class="h-full rounded-full transition-all duration-1000 ease-out" style="width:${overall}%;background:${color.hex}"></div>
        </div>
      </div>
      <div class="border-t border-gray-100 pt-2 mb-2">${details}</div>
      <div class="mt-1 text-center bg-gray-50 rounded-lg p-2">
        <div class="text-xs font-bold text-gray-700 mb-0.5">Tôi hiểu bạn ${overall}%</div>
        <div class="text-[10px] text-gray-500 italic leading-relaxed">${level.desc}</div>
      </div>
    </div>`;
}

function renderStars(idx, current) {
  let s = '';
  for (let i = 1; i <= 5; i++) {
    s += `<span onclick="rateMessage(${idx},${i})" class="text-sm cursor-pointer ${i <= current ? 'text-amber-400' : 'text-gray-300'} hover:scale-110 transition">★</span>`;
  }
  return s;
}

function rateMessage(idx, stars) {
  if (!_chatMessages[idx]) return;
  _chatMessages[idx].rating = stars === _chatMessages[idx].rating ? 0 : stars;
  localStorage.setItem('fate_feedback', JSON.stringify(_chatMessages));
  const el = document.getElementById(`stars-${idx}`);
  if (el) el.innerHTML = renderStars(idx, _chatMessages[idx].rating);
}

function showDetailModal(idx) {
  const msg = _chatMessages[idx];
  if (!msg) return;
  const body = document.getElementById('detailModalBody');
  const modal = document.getElementById('detailModal');
  if (!body || !modal) return;

  body.innerHTML = `
    <div class="mb-3 pb-3 border-b border-gray-100">
      <span class="text-xs text-gray-400">Bạn: </span><span class="text-sm text-gray-800">${msg.userMessage}</span>
      <div class="text-xs text-gray-400 mt-1">${msg.time} · ${msg.modelLabel}</div>
    </div>
    <div class="mt-3 pt-3 border-t border-gray-100">
      <div class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">📦 Phản hồi thô (JSON)</div>
      <pre class="text-[11px] bg-gray-900 text-green-400 p-3 rounded-lg whitespace-pre-wrap break-all max-h-48 overflow-y-auto">${msg.rawResponse}</pre>
    </div>`;
  modal.classList.remove('hidden');
}

function hideDetailModal() {
  const modal = document.getElementById('detailModal');
  if (modal) modal.classList.add('hidden');
}
