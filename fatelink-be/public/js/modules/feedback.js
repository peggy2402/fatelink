// ==================== FEEDBACK MODULE ====================

let _feedbackIdx = -1;

function showFeedbackModal(idx) {
  _feedbackIdx = idx;
  const msg = _chatMessages[idx];
  if (!msg) return;

  const contentEl = document.getElementById('feedbackModalContent');
  if (contentEl) {
    contentEl.innerHTML = `
      <div class="bg-gray-50 rounded-lg p-3">
        <div class="text-xs text-gray-500 mb-1">Bạn:</div>
        <div class="text-sm text-gray-800 mb-2">${msg.userMessage}</div>
        <div class="text-xs text-gray-500 mb-1">Faye:</div>
        <div class="text-sm text-gray-800">${msg.aiReply}</div>
      </div>`;
  }

  const starsContainer = document.getElementById('feedbackModalStars');
  if (starsContainer) {
    starsContainer.innerHTML = '';
    for (let i = 1; i <= 5; i++) {
      const star = document.createElement('span');
      star.className = `cursor-pointer hover:scale-110 transition ${i <= msg.rating ? 'text-amber-400' : 'text-gray-300'}`;
      star.textContent = '★';
      star.onclick = () => {
        msg.rating = i === msg.rating ? 0 : i;
        starsContainer.querySelectorAll('span').forEach((s, j) => s.className = `cursor-pointer hover:scale-110 transition ${j < msg.rating ? 'text-amber-400' : 'text-gray-300'}`);
      };
      starsContainer.appendChild(star);
    }
  }

  const textEl = document.getElementById('feedbackModalText');
  if (textEl) textEl.value = msg.feedback || '';

  const modalEl = document.getElementById('feedbackModal');
  if (modalEl) modalEl.classList.remove('hidden');
}

function hideFeedbackModal() {
  const modalEl = document.getElementById('feedbackModal');
  if (modalEl) modalEl.classList.add('hidden');
  _feedbackIdx = -1;
}

function saveFeedbackFromModal() {
  if (_feedbackIdx < 0) return;
  const msg = _chatMessages[_feedbackIdx];
  if (!msg) return;

  const starsContainer = document.getElementById('feedbackModalStars');
  const rating = starsContainer ? starsContainer.querySelectorAll('.text-amber-400').length : 0;
  msg.rating = rating;
  const textEl = document.getElementById('feedbackModalText');
  msg.feedback = textEl ? textEl.value : '';

  localStorage.setItem('fate_feedback', JSON.stringify(_chatMessages));
  const el = document.getElementById(`stars-${_feedbackIdx}`);
  if (el) el.innerHTML = renderStars(_feedbackIdx, rating);
  hideFeedbackModal();
  showToast('Đã lưu góp ý thành công', 'success');
}

function renderFeedback() {
  const grid = document.getElementById('feedbackGrid');
  const empty = document.getElementById('feedbackEmpty');
  if (!grid) return;

  const withFeedback = _chatMessages.filter(m => m.rating > 0 || (m.feedback && m.feedback.trim()));
  if (withFeedback.length === 0) {
    grid.innerHTML = '';
    if (empty) empty.classList.remove('hidden');
    return;
  }
  if (empty) empty.classList.add('hidden');

  grid.innerHTML = withFeedback.slice().reverse().map(msg => {
    const origIdx = _chatMessages.indexOf(msg);
    const stars = '★'.repeat(msg.rating) + '☆'.repeat(5 - msg.rating);
    return `<div class="bg-white rounded-xl border border-gray-200 p-4 shadow-sm hover:shadow-md transition">
      <div class="flex justify-between items-start mb-2">
        <span class="text-[10px] font-bold text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full">#Chat ${msg.id % 1000}</span>
        <span class="text-[10px] text-gray-400">${msg.time}</span>
      </div>
      <div class="text-xs text-gray-500 mb-1">👤 Bạn: <span class="text-gray-800">${msg.userMessage.length > 60 ? msg.userMessage.slice(0, 60) + '...' : msg.userMessage}</span></div>
      <div class="text-xs text-gray-500 mb-2">🤖 Faye: <span class="text-gray-800">${msg.aiReply.length > 60 ? msg.aiReply.slice(0, 60) + '...' : msg.aiReply}</span></div>
      <div class="flex items-center gap-2 mb-1">
        <span class="text-sm text-amber-400">${stars}</span>
        <span class="text-[10px] text-gray-400">(${msg.rating}/5)</span>
      </div>
      ${msg.feedback ? `<div class="text-xs text-gray-600 bg-gray-50 rounded-lg p-2 italic">"${msg.feedback}"</div>` : ''}
      <div class="flex items-center justify-between mt-2 pt-2 border-t border-gray-100">
        <span class="text-[10px] text-gray-400">${msg.modelLabel}</span>
        <button onclick="showFeedbackModal(${origIdx})" class="text-[10px] text-blue-500 hover:text-blue-700">Sửa góp ý</button>
      </div>
    </div>`;
  }).join('');
}

function clearAllFeedback() {
  if (!confirm('Xoá tất cả góp ý?')) return;
  _chatMessages = [];
  localStorage.setItem('fate_feedback', JSON.stringify(_chatMessages));
  renderFeedback();
  showToast('Đã xoá tất cả góp ý', 'success');
}
