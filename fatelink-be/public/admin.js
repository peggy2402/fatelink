const API_URL = '/api';
let token = localStorage.getItem('admin_token');
let _statusCache = {};
let _chatMessages = [];
let _feedbackIdx = -1;
let _modelRatings = JSON.parse(localStorage.getItem('fate_model_ratings') || '{}');

function loadFeedback() {
  try { _chatMessages = JSON.parse(localStorage.getItem('fate_feedback') || '[]'); } catch(e) { _chatMessages = []; }
}
loadFeedback();

// ==================== TAB PERSISTENCE ====================
function getSavedTab() {
  return localStorage.getItem('admin_last_tab') || 'configTab';
}

function saveActiveTab(tabId) {
  localStorage.setItem('admin_last_tab', tabId);
}

// ==================== TOAST ====================
function showToast(msg, type) {
  const toast = document.getElementById('toast');
  document.getElementById('toastMsg').innerText = msg;
  const icon = document.getElementById('toastIcon');
  icon.className = type === 'success'
    ? 'fas fa-check-circle text-green-400 w-5'
    : 'fas fa-exclamation-circle text-red-400 w-5';
  toast.classList.remove('translate-y-20', 'opacity-0');
  setTimeout(() => toast.classList.add('translate-y-20', 'opacity-0'), 3000);
}

// ==================== TERMINAL LOGS ====================
function addTerminalLog(message, type) {
  const container = document.getElementById('aiStatusContainer');
  const time = new Date().toLocaleTimeString('vi-VN');
  let colorClass = 'text-blue-400';
  if (type === 'SUCCESS') colorClass = 'text-green-400';
  if (type === 'ERROR') colorClass = 'text-red-400';
  if (type === 'WARN') colorClass = 'text-yellow-400';
  const placeholder = container.querySelector('.italic');
  if (placeholder) placeholder.remove();
  container.innerHTML += `<p class="border-l-2 border-gray-600 pl-3"><span class="${colorClass} font-bold">[${time}] [${type}]</span> <span class="text-gray-300 ml-1 leading-relaxed">${message}</span></p>`;
  container.scrollTop = container.scrollHeight;
  fetch(`${API_URL}/admin/logs`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ message, type })
  }).catch(() => {});
}

function clearTerminalLogs() {
  document.getElementById('aiStatusContainer').innerHTML = '<p class="text-gray-500 italic">Đã dọn dẹp hệ thống logs. Sẵn sàng ghi nhận mới...</p>';
}

// ==================== SIDEBAR ====================
function toggleSidebar() {
  document.getElementById('sidebar').classList.toggle('-translate-x-full');
  document.getElementById('sidebarOverlay').classList.toggle('hidden');
}

// ==================== LOGIN / LOGOUT ====================
if (token) showDashboard();

document.getElementById('loginForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const username = document.getElementById('username').value;
  const password = document.getElementById('password').value;
  try {
    const res = await fetch(`${API_URL}/admin/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });
    if (res.ok) {
      const data = await res.json();
      token = data.accessToken;
      localStorage.setItem('admin_token', token);
      showDashboard();
      showToast('Đăng nhập thành công', 'success');
    } else {
      showToast('Sai tài khoản hoặc mật khẩu!', 'error');
    }
  } catch (err) {
    showToast('Lỗi kết nối server', 'error');
  }
});

function logout() {
  localStorage.removeItem('admin_token');
  localStorage.removeItem('admin_last_tab');
  token = null;
  document.getElementById('loginScreen').classList.remove('hidden');
  document.getElementById('dashboardScreen').classList.add('hidden');
}

function showDashboard() {
  document.getElementById('loginScreen').classList.add('hidden');
  document.getElementById('dashboardScreen').classList.remove('hidden');
  // Restore last active tab instead of always loading config
  const savedTab = getSavedTab();
  switchTab(savedTab);
}

// ==================== TAB SWITCHING ====================
function switchTab(tabId) {
  document.getElementById('configTab').classList.add('hidden');
  document.getElementById('usersTab').classList.add('hidden');
  document.getElementById('modelsTab').classList.add('hidden');
  document.getElementById('testChatTab').classList.add('hidden');
  document.getElementById('feedbackTab').classList.add('hidden');

  ['configTab', 'usersTab', 'modelsTab', 'testChatTab', 'feedbackTab'].forEach(id => {
    const btn = document.getElementById(`btn-${id}`);
    btn.classList.remove('bg-gray-800', 'text-white');
    btn.classList.add('text-gray-400');
  });

  document.getElementById(tabId).classList.remove('hidden');
  const activeBtn = document.getElementById(`btn-${tabId}`);
  activeBtn.classList.remove('text-gray-400');
  activeBtn.classList.add('bg-gray-800', 'text-white');

  saveActiveTab(tabId);

  if (tabId === 'configTab') {
    document.getElementById('pageTitle').innerText = 'Cấu hình AI';
    loadConfig();
  } else if (tabId === 'usersTab') {
    document.getElementById('pageTitle').innerText = 'Quản lý Users';
    loadUsers();
  } else if (tabId === 'modelsTab') {
    document.getElementById('pageTitle').innerText = 'Quản lý AI Models';
    loadAiModels();
  } else if (tabId === 'testChatTab') {
    document.getElementById('pageTitle').innerText = 'Test AI Chat';
    loadModelSelector();
    renderFateInsight();
  } else if (tabId === 'feedbackTab') {
    document.getElementById('pageTitle').innerText = 'Góp ý AI';
    renderFeedback();
  }

  if (window.innerWidth < 768) {
    document.getElementById('sidebar').classList.add('-translate-x-full');
    document.getElementById('sidebarOverlay').classList.add('hidden');
  }
}

// ==================== CONFIG ====================
async function loadConfig() {
  try {
    const res = await fetch(`${API_URL}/admin/config`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    if (res.ok) {
      const data = await res.json();
      document.getElementById('systemPrompt').value = data.systemPrompt || '';
      document.getElementById('additionalKnowledge').value = data.additionalKnowledge || '';
    } else if (res.status === 401) {
      logout();
    }
  } catch (err) {
    showToast('Lỗi tải cấu hình', 'error');
  }
}

async function saveConfig() {
  const systemPrompt = document.getElementById('systemPrompt').value;
  const additionalKnowledge = document.getElementById('additionalKnowledge').value;
  try {
    const res = await fetch(`${API_URL}/admin/config`, {
      method: 'PUT',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ systemPrompt, additionalKnowledge })
    });
    if (res.ok) showToast('Lưu cấu hình thành công', 'success');
  } catch (err) {
    showToast('Lỗi khi lưu cấu hình', 'error');
  }
}

function setDefaultSystemPrompt() {
  const prev = document.getElementById('systemPrompt').value;
  if (prev && prev.trim()) localStorage.setItem('fate_system_prompt_backup', prev);

  let prompt;
  try {
    prompt = JSON.parse(prev);
  } catch(e) {
    prompt = {"system_prompt": {"version": "1.0","character": {"name": "Faye","role": "Emotionally intelligent companion","description": "Chat naturally like a real person and build genuine connections.","human_like": true},"language": {"auto_detect": true,"reply_same_language": true,"understand": {"slang": true,"abbreviations": true,"typos": true,"internet_language": true,"mixed_languages": true,"incomplete_sentences": true}},"style": {"tone": ["natural","casual","warm","friendly","emotionally-aware"],"emoji": {"enabled": true,"frequency": "low"},"message": {"length": "short_to_medium","avoid": ["robotic_language","formal_language","over_explaining","repetitive_patterns"]}},"goals": {"primary": ["build_genuine_conversation","understand_emotions","understand_personality","understand_values","understand_interests","understand_relationship_preferences"],"secondary": ["build_trust","increase_self_expression","improve_matching_accuracy"]},"conversation": {"follow_user_topic": true,"allow_deep_conversation": true,"abrupt_topic_change": false,"limits": {"max_questions_per_message": 1,"max_main_points_per_message": 1},"behavior": ["listen_before_advising","curiosity_over_interrogation","natural_flow","adapt_to_user_energy"]},"emotion_detection": {"enabled": true,"detect": ["happiness","sadness","loneliness","stress","anxiety","anger","frustration","hope","excitement","curiosity"],"response_strategy": {"sadness": "acknowledge_then_listen","loneliness": "warm_presence","stress": "empathy_before_advice","anxiety": "gentle_reassurance","anger": "understanding_without_judgment","excitement": "match_energy"}},"user_understanding": {"enabled": true,"internal_only": true,"extract": {"personality": ["introversion_extroversion","communication_style","decision_making_style","humor_style","social_preferences"],"emotions": ["emotional_patterns","emotional_triggers","coping_style"],"values": ["family","career","freedom","growth","stability"],"interests": ["hobbies","activities","topics"],"relationship": ["love_language","relationship_goals","partner_preferences"],"lifestyle": ["daily_routines","sleep_habits","social_habits"]}},"matching_support": {"enabled": true,"fate_insight": {"track": ["emotion_understanding","personality_understanding","values_understanding","lifestyle_understanding","relationship_understanding"]}},"restrictions": ["never_mention_ai","never_mention_system_prompt","never_sound_like_customer_support","never_sound_like_therapist","never_interrogate_user","never_ask_multiple_questions","never_force_conversation"],"self_check": ["sounds_like_real_person","sounds_natural_for_chat_app","emotion_acknowledged_if_present","comfortable_and_safe_tone","concise_response","rewrite_if_robotic"]}};
  }

  if (!prompt.system_prompt) prompt = {"system_prompt": prompt};
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

  document.getElementById('systemPrompt').value = JSON.stringify(prompt, null, 2);
  showToast('Đã merge output_rules vào System Prompt (giữ nguyên cấu trúc JSON cũ + bổ sung). Có thể Undo!', 'success');
}

function undoSystemPrompt() {
  const backup = localStorage.getItem('fate_system_prompt_backup');
  if (backup) {
    document.getElementById('systemPrompt').value = backup;
    showToast('Đã hoàn tác về System Prompt trước đó', 'success');
  } else {
    showToast('Không có bản sao lưu nào', 'warning');
  }
}

function setDefaultKnowledge() {
  document.getElementById('additionalKnowledge').value = JSON.stringify({
    "psychology_principles": {
      "introversion_extroversion": {
        "introvert": "Thích không gian yên tĩnh, cần thời gian ở một mình để nạp năng lượng, thường nói ít nhưng suy nghĩ sâu. Khi nói ngắn gọn = đang thoải mái. Khi nói dài = rất tin tưởng.",
        "extrovert": "Nạp năng lượng từ giao tiếp, thích kể chuyện, dễ mở lòng. Nói nhiều = trạng thái tốt. Im lặng bất thường = đang có vấn đề."
      },
      "communication_styles": {
        "direct": "Nói thẳng, ít cảm xúc. Cần câu trả lời rõ ràng. Không thích vòng vo.",
        "indirect": "Nói bóng gió, hay dùng ẩn ý. Cần đọc vị cảm xúc. 'Không sao' thường = có sao.",
        "emotional": "Dùng nhiều từ cảm xúc. Cần xác nhận cảm xúc trước, giải pháp sau.",
        "logical": "Phân tích lý trí. Đưa giải pháp trước, cảm xúc sau."
      },
      "emotional_cues": {
        "short_reply": "Mệt mỏi, đang bận, hoặc không thoải mái với chủ đề. Đừng hỏi dồn.",
        "long_reply": "Đầu tư vào cuộc trò chuyện, đang cởi mở. Có thể khai thác sâu hơn.",
        "avoiding_topic": "Chuyển chủ đề = chưa sẵn sàng. Tôn trọng, quay lại sau.",
        "self_disclosure": "Chia sẻ thông tin cá nhân = tin tưởng. Đây là cơ hội để hiểu sâu.",
        "humor_deflection": "Dùng hài hước để né cảm xúc thật. Nhẹ nhàng quay lại sau.",
        "silence": "Im lặng trong chat = đang suy nghĩ, không phải từ chối."
      }
    },
    "attachment_styles": {
      "secure": "Dễ gần, giao tiếp lành mạnh, cân bằng. Tôn trọng không gian của đối phương.",
      "anxious": "Cần xác nhận nhiều, sợ bị bỏ rơi, hay nhắn tin liên tục. Trấn an nhẹ nhàng.",
      "avoidant": "Giữ khoảng cách, ngại cam kết, cần không gian riêng. Đừng tạo áp lực.",
      "fearful_avoidant": "Vừa muốn gần vừa sợ gần. Kiên nhẫn và ổn định là chìa khóa."
    },
    "reading_signals": {
      "over_enthusiasm_early": "Quá nhiệt tình ban đầu có thể là red flag (love bombing) hoặc tính cách tự nhiên. Cần quan sát thêm.",
      "inconsistent_messages": "Lúc nóng lúc lạnh = đang do dự, hoặc avoidant attachment.",
      "future_faking": "Nói về tương lai xa quá sớm = có thể đang tưởng tượng hơn là thực tế.",
      "mirroring": "Bắt chước cách nói/cảm xúc = đang cố tạo kết nối (có thể tốt hoặc giả tạo).",
      "defensive_humor": "Khi bị hỏi về cảm xúc mà đùa = chưa sẵn sàng đối diện."
    },
    "conversation_psychology": {
      "open_ended_triggers": [
        "Kể tôi nghe về...",
        "Điều gì làm bạn...",
        "Bạn cảm thấy thế nào khi..."
      ],
      "trust_building": "Chia sẻ một chút về bản thân trước khi hỏi sâu. Con người tin tưởng người có điểm chung.",
      "validation_first": "Luôn xác nhận cảm xúc trước khi đưa ra góc nhìn khác. 'Mình hiểu bạn cảm thấy thế...'",
      "pause_power": "Sau khi hỏi câu sâu, im lặng (trong chat là chờ đợi) tạo không gian cho đối phương mở lòng."
    },
    "personality_indicators": {
      "storyteller": "Kể chuyện dài, nhiều chi tiết → giàu cảm xúc, thích kết nối sâu.",
      "fact_giver": "Chỉ nói sự kiện, ít cảm xúc → lý trí, có thể là avoidant hoặc chưa thoải mái.",
      "question_asker": "Toàn hỏi về đối phương → né tránh nói về bản thân hoặc thực sự quan tâm.",
      "philosopher": "Nói về cuộc sống, ý nghĩa → người suy tư, thích kết nối tri kỷ."
    },
    "vietnamese_culture": {
      "indirect_communication": "Người Việt thường nói giảm nói tránh, đặc biệt trong tình cảm. 'Để suy nghĩ thêm' thường là từ chối nhẹ.",
      "family_influence": "Gia đình là yếu tố quan trọng trong quyết định tình cảm của người Việt.",
      "face_saving": "Tránh làm mất mặt đối phương. Phê bình nên nhẹ nhàng, khen nên rõ ràng.",
      "age_respect": "Tuổi tác có vai trò trong giao tiếp. Xưng hô phù hợp tạo thiện cảm."
    },
    "emotional_intelligence_tips": [
      "Khi ai đó nói 'tôi không biết' - họ thực sự biết nhưng chưa sẵn sàng nói.",
      "Người hay nói 'không sao' - thường là có sao.",
      "Giận dữ thường là mặt nạ của tổn thương hoặc sợ hãi.",
      "Người hay tự ti thường cần validation hơn người tự tin.",
      "Khi ai đó hỏi ý kiến bạn nhưng không nghe - họ chỉ cần xác nhận quyết định của họ."
    ],
    "matching_knowledge": {
      "complementary_vs_similar": "Tính cách tương đồng tạo thấu hiểu ban đầu. Tính cách bổ sung tạo phát triển lâu dài.",
      "proximity_effect": "Con người dễ yêu người gần gũi, thường xuyên tương tác.",
      "mere_exposure": "Tiếp xúc nhiều lần làm tăng thiện cảm. Dùng trong chat thường xuyên.",
      "similarity_attraction": "Điểm chung nhỏ nhất (cùng thích nhạc, cùng quê) tạo kết nối mạnh.",
      "reciprocal_liking": "Biết đối phương thích mình → tự động thích lại. Tạo không gian an toàn cho cảm xúc."
    }
  }, null, 2);
  showToast('Đã tải kiến thức tâm lý học hành vi', 'success');
}

// ==================== USERS ====================
let allUsersData = [];
let filteredUsersData = [];
let currentPage = 1;
let itemsPerPage = 5;

async function loadUsers() {
  try {
    const res = await fetch(`${API_URL}/admin/users`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    if (res.ok) {
      allUsersData = await res.json();
      filterUsers();
      updateDashboardStats(allUsersData);
    }
  } catch (err) {
    showToast('Lỗi tải danh sách users', 'error');
  }
}

let emotionChartInstance = null;
function updateDashboardStats(users) {
  document.getElementById('statTotalUsers').innerText = users.length;
  document.getElementById('statActiveUsers').innerText = users.filter(u => !u.isBanned).length;
  document.getElementById('statBannedUsers').innerText = users.filter(u => u.isBanned).length;
  const emotions = {};
  users.forEach(u => {
    const emo = u.latestEmotion || 'Chưa cập nhật';
    emotions[emo] = (emotions[emo] || 0) + 1;
  });
  const ctx = document.getElementById('emotionChart').getContext('2d');
  if (emotionChartInstance) emotionChartInstance.destroy();
  emotionChartInstance = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: Object.keys(emotions),
      datasets: [{
        data: Object.values(emotions),
        backgroundColor: ['#10b981', '#ef4444', '#f59e0b', '#3b82f6', '#8b5cf6', '#6b7280', '#ec4899'],
        borderWidth: 0, cutout: '70%'
      }]
    },
    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'right', labels: { boxWidth: 10, font: { size: 11 } } } } }
  });
}

function filterUsers() {
  const filterValue = document.getElementById('userFilter').value;
  const searchValue = document.getElementById('userSearch').value.toLowerCase();
  filteredUsersData = allUsersData.filter(u => {
    const name = (u.name || u.email || 'Người dùng ẩn danh').toLowerCase();
    const matchesSearch = name.includes(searchValue) || (u._id && u._id.includes(searchValue));
    const matchesStatus = filterValue === 'all' ? true : (filterValue === 'active' ? !u.isBanned : u.isBanned);
    return matchesSearch && matchesStatus;
  });
  currentPage = 1;
  renderPagination();
}

function renderPagination() {
  const totalUsers = filteredUsersData.length;
  const totalPages = Math.ceil(totalUsers / itemsPerPage) || 1;
  document.getElementById('totalUsersDisplay').innerText = totalUsers;
  document.getElementById('totalPagesDisplay').innerText = totalPages;
  document.getElementById('currentPageDisplay').innerText = currentPage;
  document.getElementById('btnPrevPage').disabled = currentPage === 1;
  document.getElementById('btnNextPage').disabled = currentPage === totalPages;
  const startIdx = (currentPage - 1) * itemsPerPage;
  renderUsers(filteredUsersData.slice(startIdx, startIdx + itemsPerPage));
}

function prevPage() { if (currentPage > 1) { currentPage--; renderPagination(); } }
function nextPage() {
  const totalPages = Math.ceil(filteredUsersData.length / itemsPerPage) || 1;
  if (currentPage < totalPages) { currentPage++; renderPagination(); }
}
function changeItemsPerPage() {
  itemsPerPage = parseInt(document.getElementById('itemsPerPage').value, 10);
  currentPage = 1;
  renderPagination();
}

function renderUsers(users) {
  const tbody = document.getElementById('usersTableBody');
  tbody.innerHTML = '';
  users.forEach(user => {
    const isBanned = user.isBanned || false;
    const name = user.name || user.email || 'Người dùng ẩn danh';
    const date = new Date(user.createdAt || Date.now()).toLocaleDateString('vi-VN');
    const tr = document.createElement('tr');
    tr.className = "block sm:table-row border border-gray-200 sm:border-none mb-4 sm:mb-0 bg-white sm:bg-transparent shadow-sm sm:shadow-none rounded-xl sm:rounded-none hover:bg-gray-50 transition-colors";
    tr.innerHTML = `
      <td class="block sm:table-cell px-4 py-3 sm:px-6 sm:py-4 whitespace-nowrap">
        <div class="flex items-center justify-between sm:justify-start">
          <div class="flex items-center">
            <div class="flex-shrink-0 h-10 w-10">
              <img class="h-10 w-10 rounded-full object-cover shadow-sm" src="${user.avatarUrl || 'https://ui-avatars.com/api/?name='+name+'&background=0D8ABC&color=fff'}" alt="Avatar">
            </div>
            <div class="ml-4">
              <div class="text-sm font-medium text-gray-900">${name}</div>
              <div class="text-xs text-gray-500 font-mono mt-1">ID: ${user._id}</div>
            </div>
          </div>
          <span class="sm:hidden px-2 py-1 inline-flex text-[10px] leading-5 font-bold rounded-full ${isBanned ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'}">${isBanned ? 'Đã khóa' : 'Hoạt động'}</span>
        </div>
      </td>
      <td class="hidden sm:table-cell px-6 py-4 whitespace-nowrap">
        <span class="px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${isBanned ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'}">${isBanned ? 'Đã khóa' : 'Hoạt động'}</span>
      </td>
      <td class="block sm:table-cell px-4 py-2 sm:px-6 sm:py-4 whitespace-nowrap text-sm text-gray-500 flex justify-between sm:table-cell border-t border-gray-100 sm:border-none">
        <span class="sm:hidden font-semibold text-gray-600">Ngày tham gia:</span> <span>${date}</span>
      </td>
      <td class="block sm:table-cell px-4 py-3 sm:px-6 sm:py-4 whitespace-nowrap text-right text-sm font-medium border-t border-gray-100 sm:border-none">
        <button onclick="toggleBan('${user._id}', ${isBanned})" class="w-full sm:w-auto px-4 py-2 sm:px-3 sm:py-1 rounded border ${isBanned ? 'border-green-500 text-green-600 hover:bg-green-50' : 'border-red-500 text-red-600 hover:bg-red-50'} transition shadow-sm font-bold sm:font-normal">${isBanned ? 'MỞ KHÓA TÀI KHOẢN' : 'KHÓA (BAN)'}</button>
      </td>`;
    tbody.appendChild(tr);
  });
}

async function toggleBan(userId, currentStatus) {
  if (!confirm(`Bạn có chắc muốn ${currentStatus ? 'mở khóa' : 'khóa'} tài khoản này?`)) return;
  try {
    const res = await fetch(`${API_URL}/admin/users/${userId}/ban`, {
      method: 'PUT',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ isBanned: !currentStatus })
    });
    if (res.ok) {
      showToast(!currentStatus ? 'Đã khóa tài khoản' : 'Đã mở khóa', 'success');
      loadUsers();
    }
  } catch (err) {
    showToast('Lỗi thực thi lệnh', 'error');
  }
}

// ==================== DOWNLOAD LOGS ====================
async function downloadLogs() {
  try {
    const res = await fetch(`${API_URL}/admin/logs/download`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    if (res.ok) {
      const blob = await res.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'fatelink_admin_logs.txt';
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    } else {
      showToast('Chưa có file log', 'error');
    }
  } catch (e) {
    showToast('Lỗi tải file', 'error');
  }
}

// ==================== MODELS CRUD ====================
let allModelsData = [];
let filteredModelsData = [];
let currentModelPage = 1;
let modelsPerPage = 20;

const modelModal = document.getElementById('modelModal');
const modelForm = document.getElementById('modelForm');

function showModelModal(model) {
  modelForm.reset();
  if (model) {
    document.getElementById('modelModalTitle').innerText = 'Chỉnh sửa Model AI';
    document.getElementById('modelIdField').value = model.id;
    document.getElementById('displayName').value = model.displayName;
    document.getElementById('providerName').value = model.providerName;
    document.getElementById('modelIdentifier').value = model.modelId;
  } else {
    document.getElementById('modelModalTitle').innerText = 'Thêm Model AI Mới';
    document.getElementById('modelIdField').value = '';
  }
  modelModal.classList.remove('hidden');
}

function hideModelModal() {
  modelModal.classList.add('hidden');
}

modelForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  const id = document.getElementById('modelIdField').value;
  const existingModel = allModelsData.find(m => m.id === id);
  const dto = {
    displayName: document.getElementById('displayName').value,
    providerName: document.getElementById('providerName').value,
    modelId: document.getElementById('modelIdentifier').value,
    isEnabled: true,
    priority: existingModel && existingModel.priority !== undefined ? existingModel.priority : 0
  };
  const url = id ? `${API_URL}/admin/models/${id}` : `${API_URL}/admin/models`;
  const method = id ? 'PUT' : 'POST';
  try {
    const res = await fetch(url, {
      method,
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(dto)
    });
    if (res.ok) {
      showToast(id ? 'Cập nhật thành công!' : 'Thêm model thành công!', 'success');
      addTerminalLog(`Đã ${id ? 'cập nhật' : 'thêm mới'} Model <b class="text-white">${dto.displayName}</b> (${dto.modelId}) của nhà cung cấp ${dto.providerName}.`, 'SUCCESS');
      hideModelModal();
      loadAiModels();
    } else {
      const errData = await res.json().catch(() => ({}));
      let errMsg = errData.message || 'Dữ liệu không hợp lệ hoặc Model ID đã tồn tại!';
      if (Array.isArray(errMsg)) errMsg = errMsg.join(', ');
      showToast(`Lỗi: ${errMsg}`, 'error');
    }
  } catch (err) {
    showToast('Lỗi thực thi', 'error');
  }
});

async function loadAiModels() {
  try {
    const res = await fetch(`${API_URL}/admin/models`, { headers: { 'Authorization': `Bearer ${token}` } });
    if (res.ok) {
      allModelsData = await res.json();
      // Restore cached status
      try {
        const cached = sessionStorage.getItem('ai_status_cache');
        if (cached) _statusCache = JSON.parse(cached);
      } catch(e) {}
      allModelsData.forEach(m => {
        if (_statusCache[m.modelId]) {
          m._apiStatus = _statusCache[m.modelId];
        }
      });
      filterModels();
      renderPriorityZones();
    }
  } catch (err) {
    showToast('Lỗi tải danh sách models', 'error');
  }
}

function filterModels() {
  const filterValue = document.getElementById('modelFilter').value;
  const providerValue = document.getElementById('providerFilter').value;
  const searchValue = document.getElementById('modelSearch').value.toLowerCase();
  filteredModelsData = allModelsData.filter(m => {
    const textStr = (m.displayName + ' ' + m.modelId + ' ' + m.providerName).toLowerCase();
    const matchesSearch = textStr.includes(searchValue);
    const isEnabled = m.isEnabled !== false;
    const matchesStatus = filterValue === 'all' ? true : (filterValue === 'enabled' ? isEnabled : !isEnabled);
    const matchesProvider = providerValue === 'all' ? true : m.providerName === providerValue;
    return matchesSearch && matchesStatus && matchesProvider;
  });
  renderModelPagination();
}

function renderModelPagination() {
  renderModels(filteredModelsData);
}

function prevModelPage() {}
function nextModelPage() {}
function changeModelsPerPage() {}

function renderModels(models) {
  const grid = document.getElementById('modelsCardGrid');
  const empty = document.getElementById('modelsEmptyState');
  if (!grid) return;
  grid.innerHTML = '';
  if (models.length === 0) {
    empty.classList.remove('hidden');
    return;
  }
  empty.classList.add('hidden');
  const firstEnabled = allModelsData.filter(m => m.isEnabled !== false);
  const primaryId = firstEnabled[0]?.id;
  const fallbackId = firstEnabled.slice(-1)[0]?.id;

  models.forEach((model, idx) => {
    const isEnabled = model.isEnabled !== false;
    const isPrimary = isEnabled && primaryId === model.id;
    const isFallback = isEnabled && fallbackId === model.id;
    const borderClass = isPrimary ? 'border-amber-400 bg-amber-50' : isFallback ? 'border-blue-400 bg-blue-50' : isEnabled ? 'border-gray-200 bg-white hover:border-blue-300' : 'border-gray-200 bg-gray-100 opacity-60';
    const card = document.createElement('div');
    card.className = `relative rounded-xl border-2 p-3 flex flex-col items-center text-center transition-all hover:shadow-lg cursor-pointer ${borderClass}`;
    if (isEnabled) card.onclick = () => showPriorityModal(model);

    let statusText = 'Chưa kiểm tra';
    let statusStyle = 'bg-gray-200 text-gray-600';
    if (model._apiStatus) {
      const s = model._apiStatus;
      if (s.status === 'LOADING') {
        statusText = 'Đang test...';
        statusStyle = 'bg-blue-200 text-blue-700';
      } else if (s.status === 'SUCCESS') {
        statusText = s.ping || 'OK';
        statusStyle = 'bg-green-200 text-green-800';
      } else {
        statusText = 'Lỗi';
        statusStyle = 'bg-red-200 text-red-700';
      }
    }

    card.innerHTML = `
      <div class="w-full flex justify-between items-start mb-1">
        <span class="text-[10px] font-bold text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full">#${idx + 1}</span>
        ${!isEnabled ? '<span class="text-[10px] text-red-500 font-bold">TẮT</span>' : ''}
      </div>
      <div class="text-sm font-bold text-gray-800 leading-tight mb-1">${model.providerName}</div>
      <div class="text-xs font-semibold text-gray-900 mb-1">${model.displayName}</div>
      <div class="text-[10px] font-mono text-gray-400 bg-gray-100 px-2 py-0.5 rounded mb-2 truncate max-w-full">${model.modelId}</div>
      <div class="flex flex-wrap gap-1 justify-center mb-2">
        <span class="text-[10px] font-bold px-2 py-0.5 rounded-full ${statusStyle}">${statusText}</span>
        ${isPrimary ? '<span class="text-[10px] font-bold text-amber-600 bg-amber-100 px-2 py-0.5 rounded-full border border-amber-300">🔥 #1</span>' : ''}
        ${isFallback && !isPrimary ? '<span class="text-[10px] font-bold text-blue-600 bg-blue-100 px-2 py-0.5 rounded-full border border-blue-300">🔁 Fallback</span>' : ''}
      </div>
      <div class="w-full flex gap-1 mt-1 pt-2 border-t border-gray-200 ${isEnabled ? '' : 'hidden'}">
        <button onclick="event.stopPropagation();toggleAiModel('${model.id}',${isEnabled})" class="flex-1 text-[10px] py-1.5 rounded ${isEnabled ? 'text-orange-600 bg-orange-50 hover:bg-orange-100' : 'text-green-600 bg-green-50 hover:bg-green-100'} font-semibold transition">${isEnabled ? 'Tắt' : 'Bật'}</button>
        <button onclick="event.stopPropagation();showModelModal(${JSON.stringify(model).replace(/'/g, "\\'")})" class="flex-1 text-[10px] py-1.5 rounded text-blue-600 bg-blue-50 hover:bg-blue-100 font-semibold transition">Sửa</button>
        <button onclick="event.stopPropagation();deleteAiModel('${model.id}')" class="flex-1 text-[10px] py-1.5 rounded text-red-600 bg-red-50 hover:bg-red-100 font-semibold transition">Xóa</button>
      </div>
    `;
    grid.appendChild(card);
  });
}

let _priorityTargetModel = null;
function showPriorityModal(model) {
  _priorityTargetModel = model;
  document.getElementById('priorityModalModelName').innerHTML = `<b>${model.displayName}</b><br><span class="text-gray-400">${model.providerName} - ${model.modelId}</span>`;
  document.getElementById('priorityModal').classList.remove('hidden');
}
function hidePriorityModal() {
  document.getElementById('priorityModal').classList.add('hidden');
  _priorityTargetModel = null;
}
async function setPriorityForModel(zone) {
  if (!_priorityTargetModel) return;
  const model = _priorityTargetModel;
  const allIds = allModelsData.map(m => m.id);
  const idx = allIds.indexOf(model.id);
  if (idx === -1) return;
  allIds.splice(idx, 1);
  if (zone === 'primary') allIds.unshift(model.id);
  else allIds.push(model.id);
  hidePriorityModal();
  try {
    const res = await fetch(`${API_URL}/admin/models/reorder`, {
      method: 'PUT',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ modelIds: allIds })
    });
    if (res.ok) {
      showToast(zone === 'primary' ? `✅ ${model.displayName} là Model ưu tiên #1!` : `✅ ${model.displayName} là Model fallback!`, 'success');
      await loadAiModels();
    }
  } catch(e) { showToast('Lỗi khi thiết lập', 'error'); }
}

async function toggleAiModel(id, currentStatus) {
  try {
    await fetch(`${API_URL}/admin/models/${id}`, {
      method: 'PUT',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ isEnabled: !currentStatus })
    });
    showToast(!currentStatus ? 'Đã BẬT Model!' : 'Đã TẮT Model!', 'success');
    addTerminalLog(`Hệ thống đã ${!currentStatus ? 'KÍCH HOẠT' : 'VÔ HIỆU HÓA'} model (ID Database: ${id})`, 'WARN');
    loadAiModels();
  } catch(e) {
    showToast('Lỗi khi đổi trạng thái', 'error');
  }
}

async function deleteAiModel(id) {
  if (!confirm('Bạn có chắc muốn xóa model này?')) return;
  try {
    await fetch(`${API_URL}/admin/models/${id}`, { method: 'DELETE', headers: { 'Authorization': `Bearer ${token}` } });
    showToast('Xóa model thành công!', 'success');
    addTerminalLog(`Đã xóa vĩnh viễn model khỏi cơ sở dữ liệu (ID: ${id})`, 'WARN');
    loadAiModels();
  } catch (err) {
    showToast('Lỗi khi xóa', 'error');
  }
}

// ==================== AI STATUS CHECK ====================
async function checkAiModels() {
  const btn = document.getElementById('btnCheckAi');
  const btnText = document.getElementById('btnCheckAiText');
  const container = document.getElementById('aiStatusContainer');
  btn.disabled = true;
  btnText.innerText = 'Đang quét...';
  container.innerHTML = '<p class="text-blue-400 animate-pulse">> Đang gửi gói tin ping đến các máy chủ AI, vui lòng chờ...</p>';
  allModelsData.forEach(model => { model._apiStatus = { status: 'LOADING' }; });
  renderModelPagination();
  try {
    const res = await fetch(`${API_URL}/admin/ai-status`, { headers: { 'Authorization': `Bearer ${token}` } });
    if (res.ok) {
      const statuses = await res.json();
      container.innerHTML = '';
      const groupedData = statuses.reduce((acc, current) => {
        const provider = current.provider || 'Unknown Provider';
        if (!acc[provider]) acc[provider] = [];
        if (current.modelId || current.displayName) acc[provider].push(current);
        return acc;
      }, {});
      addTerminalLog(`=== BÁO CÁO TRẠNG THÁI AI PROVIDERS ===`, 'INFO');
      for (const [provider, models] of Object.entries(groupedData)) {
        addTerminalLog(`📦 Provider: <b class="text-white">${provider}</b>`, 'INFO');
        if (models.length === 0) {
          addTerminalLog(`&nbsp;&nbsp;&nbsp;↳ Models: N/A (Chưa cấu hình model nào)`, 'WARN');
        } else {
          models.forEach((m, index) => {
            const validName = m.displayName || m.modelId || 'Model ẩn danh';
            if (m.status === 'SUCCESS') {
              addTerminalLog(`&nbsp;&nbsp;&nbsp;↳ ${index + 1}. Model: <span class="text-blue-300">[${validName}]</span> -> Trạng thái: Thành công (${m.ping})`, 'SUCCESS');
            } else {
              addTerminalLog(`&nbsp;&nbsp;&nbsp;↳ ${index + 1}. Model: <span class="text-blue-300">[${validName}]</span> -> Trạng thái: Lỗi - ${m.error}`, 'ERROR');
            }
          });
        }
      }
      allModelsData.forEach(model => {
        const statusObj = statuses.find(s => s.modelId === model.modelId);
        model._apiStatus = statusObj || { status: 'ERROR', error: 'Chưa có thông tin phản hồi' };
        if (statusObj) _statusCache[model.modelId] = statusObj;
        else _statusCache[model.modelId] = { status: 'ERROR', error: 'Chưa có thông tin' };
      });
      sessionStorage.setItem('ai_status_cache', JSON.stringify(_statusCache));
      renderModelPagination();
      renderPriorityZones();
    }
  } catch (err) {
    showToast('Lỗi khi kiểm tra trạng thái AI', 'error');
    addTerminalLog(`Gặp sự cố kết nối mạng nghiêm trọng, không thể lấy dữ liệu từ máy chủ.`, 'ERROR');
  } finally {
    btn.disabled = false;
    btnText.innerText = 'Cập nhật trạng thái';
  }
}

// ==================== PRIORITY ZONES ====================
function renderPriorityZones() {
  const enabled = allModelsData.filter(m => m.isEnabled !== false);
  const primaryEl = document.getElementById('primaryZoneModel');
  const fallbackEl = document.getElementById('fallbackZoneModel');
  if (!primaryEl || !fallbackEl) return;
  if (enabled.length === 0) {
    primaryEl.innerHTML = '<span class="text-gray-400 italic">Chưa có Model nào được bật</span>';
    fallbackEl.innerHTML = '<span class="text-gray-400 italic">Chưa có Model nào được bật</span>';
    return;
  }
  const primary = enabled[0];
  const fallback = enabled[enabled.length - 1];
  const primaryStatus = _statusCache[primary.modelId];
  const fallbackStatus = _statusCache[fallback.modelId];
  const primaryDot = primaryStatus === 'SUCCESS' ? '🟢' : primaryStatus ? '🔴' : '❓';
  const fallbackDot = fallbackStatus === 'SUCCESS' ? '🟢' : fallbackStatus ? '🔴' : '❓';
  primaryEl.innerHTML = `${primaryDot} <b>${primary.displayName}</b> <span class="text-gray-400">(${primary.providerName} - ${primary.modelId})</span>`;
  fallbackEl.innerHTML = `${fallbackDot} <b>${fallback.displayName}</b> <span class="text-gray-400">(${fallback.providerName} - ${fallback.modelId})</span>`;
}



// ==================== TEST AI CHAT WITH MODEL SELECTOR ====================
async function loadModelSelector() {
  const select = document.getElementById('chatModelSelector');
  if (!select) return;
  const currentValue = select.value;
  select.innerHTML = '<option value="">⟳ Theo thứ tự ưu tiên (tự động)</option>';
  try {
    const res = await fetch(`${API_URL}/admin/models`, { headers: { 'Authorization': `Bearer ${token}` } });
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
  e.preventDefault();
  const input = document.getElementById('chatInput');
  const message = input.value;
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

  // Remove empty state
  const empty = chatBox.querySelector('.text-center.text-gray-400');
  if (empty) empty.remove();

  // User bubble
  chatBox.innerHTML += `<div class="flex justify-end mb-3 items-end gap-2">
    <div class="max-w-[70%]">
      <div class="bg-blue-600 text-white px-4 py-2.5 rounded-2xl rounded-br-sm shadow-sm break-words">${message}</div>
      <div class="text-[10px] text-gray-400 text-right mt-0.5 mr-1">${time}</div>
    </div>
    <div class="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center text-sm shrink-0 mb-1">👤</div>
  </div>`;
  // Typing indicator
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
    const res = await fetch(`${API_URL}/admin/ai-chat`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    document.getElementById(`typing-${msgId}`).remove();
    const textResponse = await res.text();
    let parsed = null;
    try { parsed = JSON.parse(textResponse); } catch(e) {}

    const replyText = parsed && parsed.reply ? parsed.reply : textResponse;
    const idx = _chatMessages.length;

    _chatMessages.push({
      id: msgId, time, userMessage: message, aiReply: replyText,
      rawResponse: textResponse, parsed,
      modelLabel, modelId, providerName,
      rating: 0, feedback: ''
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
        <div class="flex items-center gap-2 mt-0.5 ml-1">
          <span class="text-[10px] text-gray-400">${time}</span>
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
  document.getElementById('chatBox').innerHTML = '<div class="text-center text-gray-400 italic mt-10">Bắt đầu trò chuyện để kiểm tra AI nhé!</div>';
  _chatMessages = [];
  localStorage.setItem('fate_feedback', JSON.stringify(_chatMessages));
  resetFateInsight();
}

// ==================== FATE INSIGHT ====================
const FATE_WEIGHTS = { emotion: 0.25, personality: 0.25, values: 0.20, lifestyle: 0.15, relationship: 0.15 };
const FATE_KEYWORDS = {
  emotion: ['vui', 'buồn', 'lo lắng', 'căng thẳng', 'cô đơn', 'tự tin', 'sợ hãi', 'hạnh phúc', 'tức giận', 'thất vọng', 'hy vọng', 'yêu thương', 'ghét', 'nhớ nhung', 'đau khổ', 'mệt mỏi', 'chán nản', 'phấn khích', 'bình yên', 'cô độc', 'tuyệt vọng', 'biết ơn'],
  personality: ['hướng nội', 'hướng ngoại', 'chủ động', 'điềm tĩnh', 'sáng tạo', 'nhút nhát', 'tự ti', 'kiên nhẫn', 'nóng tính', 'dễ gần', 'khó tính', 'thẳng thắn', 'tế nhị', 'hài hước', 'nghiêm túc', 'sôi nổi', 'trầm tính', 'cẩn thận', 'bốc đồng', 'lý trí', 'tình cảm'],
  values: ['gia đình', 'sự nghiệp', 'tự do', 'học tập', 'trách nhiệm', 'tiền bạc', 'tình yêu', 'bạn bè', 'sức khỏe', 'công việc', 'đam mê', 'tín ngưỡng', 'lương thiện', 'trung thực', 'bao dung', 'thành công', 'hạnh phúc gia đình'],
  lifestyle: ['thể thao', 'du lịch', 'thức khuya', 'dậy sớm', 'ẩm thực', 'cà phê', 'sách vở', 'xem phim', 'âm nhạc', 'chơi game', 'nấu ăn', 'chạy bộ', 'yoga', 'thiền định', 'vẽ tranh', 'ca hát', 'dã ngoại', 'câu cá', 'làm vườn'],
  relationship: ['người yêu', 'kết hôn', 'bạn đồng hành', 'tri kỷ', 'tâm sự', 'hẹn hò', 'kết bạn', 'tình cảm', 'chia sẻ', 'đồng điệu', 'tâm hồn', 'cưới hỏi', 'yêu đương', 'quan tâm', 'thấu hiểu', 'chung thủy', 'lãng mạn']
};

let _fate = {
  scores: { emotion: 0, personality: 0, values: 0, lifestyle: 0, relationship: 0 },
  history: [],
  messages: 0
};

function resetFateInsight() {
  _fate = {
    scores: { emotion: 0, personality: 0, values: 0, lifestyle: 0, relationship: 0 },
    history: [],
    messages: 0
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
  return Math.round(
    s.emotion * 0.25 + s.personality * 0.25 + s.values * 0.20 + s.lifestyle * 0.15 + s.relationship * 0.15
  );
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

function getFateArrow(current, prev) {
  if (prev === null || prev === undefined) return { icon: '—', color: 'text-gray-400' };
  if (current > prev) return { icon: '↑', color: 'text-green-500' };
  if (current < prev) return { icon: '↓', color: 'text-red-500' };
  return { icon: '→', color: 'text-yellow-500' };
}

function renderFateInsight() {
  const panel = document.getElementById('fateInsightPanel');
  if (!panel) return;

  const overall = getFateOverall();
  const level = getFateLevel(overall);
  const color = getFateColor(overall);
  const prev = _fate.history.length > 0 ? _fate.history[_fate.history.length - 1] : null;
  const arrow = getFateArrow(overall, prev);

  const dimMeta = {
    emotion: { label: '❤️ Emotion', icon: '❤️' },
    personality: { label: '🎭 Personality', icon: '🎭' },
    values: { label: '🌱 Core Values', icon: '🌱' },
    lifestyle: { label: '🏃 Lifestyle', icon: '🏃' },
    relationship: { label: '💕 Relationship', icon: '💕' }
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
          <span class="text-2xl font-black ${arrow.color}">${arrow.icon}</span>
        </div>
        <div class="flex items-center justify-center gap-2 mt-1">
          <span class="inline-block w-2 h-2 rounded-full" style="background:${color.hex}"></span>
          <span class="text-sm font-semibold" style="color:${color.hex}">${level.name}</span>
        </div>
        <div class="w-full h-3 bg-gray-200 rounded-full mt-2 overflow-hidden">
          <div class="h-full rounded-full transition-all duration-1000 ease-out" style="width:${overall}%;background:${color.hex}"></div>
        </div>
        <div class="text-[10px] text-gray-400 mt-1">${color.label} · ${_fate.messages} tin nhắn</div>
      </div>
      <div class="border-t border-gray-100 pt-2 mb-2">
        ${details}
      </div>
      <div class="mt-1 text-center bg-gray-50 rounded-lg p-2">
        <div class="text-xs font-bold text-gray-700 mb-0.5">Tôi hiểu bạn ${overall}%</div>
        <div class="text-[10px] text-gray-500 italic leading-relaxed">${level.desc}</div>
      </div>
    </div>
    <div class="mt-3 text-center text-[10px] text-gray-400">
      Nhấn <button onclick="resetFateInsight()" class="text-blue-500 hover:underline">Đặt lại</button> để bắt đầu lại
    </div>`;
}

// ==================== PER-MESSAGE RATING ====================
function renderStars(idx, current) {
  let s = '';
  for (let i = 1; i <= 5; i++) s += `<span onclick="rateMessage(${idx},${i})" class="text-sm cursor-pointer ${i <= current ? 'text-amber-400' : 'text-gray-300'} hover:scale-110 transition">★</span>`;
  return s;
}

function rateMessage(idx, stars) {
  if (!_chatMessages[idx]) return;
  _chatMessages[idx].rating = stars === _chatMessages[idx].rating ? 0 : stars;
  localStorage.setItem('fate_feedback', JSON.stringify(_chatMessages));
  const el = document.getElementById(`stars-${idx}`);
  if (el) el.innerHTML = renderStars(idx, _chatMessages[idx].rating);
}

// ==================== DETAIL MODAL ====================
function showDetailModal(idx) {
  const msg = _chatMessages[idx];
  if (!msg) return;
  const body = document.getElementById('detailModalBody');
  const p = msg.parsed;
  let html = `<div class="mb-3 pb-3 border-b border-gray-100">
    <span class="text-xs text-gray-400">Bạn: </span><span class="text-sm text-gray-800">${msg.userMessage}</span>
    <div class="text-xs text-gray-400 mt-1">${msg.time} · ${msg.modelLabel}</div>
  </div>`;

  if (p && p.detected_emotions) {
    html += `<div class="mb-3"><div class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">❤️ Cảm xúc phát hiện</div>`;
    Object.entries(p.detected_emotions).forEach(([k, v]) => {
      const bar = v > 0 ? `<div class="w-full h-1.5 bg-gray-200 rounded-full mt-0.5"><div class="h-full rounded-full bg-gradient-to-r from-red-400 to-orange-400" style="width:${(v / 10) * 100}%"></div></div>` : '';
      html += `<div class="flex justify-between text-xs mb-1"><span>${k}</span><span class="font-bold">${v}/10</span></div>${bar}`;
    });
    html += `</div>`;
  }

  if (p && p.detected_personality) {
    const labels = ['Hướng ngoại', 'Tận tâm', 'Cởi mở'];
    html += `<div class="mb-3"><div class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">🎭 Tính cách</div>`;
    p.detected_personality.forEach((v, i) => {
      html += `<div class="flex justify-between text-xs mb-1"><span>${labels[i] || '#' + (i + 1)}</span><span class="font-bold">${v}/10</span></div>`;
    });
    html += `</div>`;
  }

  if (p && p.latestEmotion) {
    html += `<div class="mb-3"><span class="text-xs font-bold text-gray-500">Cảm xúc gần nhất: </span><span class="text-sm font-bold text-purple-600">${p.latestEmotion}</span></div>`;
  }

  if (p && p.is_ready_to_match !== undefined) {
    html += `<div class="mb-3"><span class="text-xs font-bold text-gray-500">Sẵn sàng ghép đôi: </span><span class="text-sm ${p.is_ready_to_match ? 'text-green-600' : 'text-gray-400'}">${p.is_ready_to_match ? '✅ Có' : '⏳ Chưa'}</span></div>`;
  }

  html += `<div class="mt-3 pt-3 border-t border-gray-100">
    <div class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">📦 Phản hồi thô (JSON)</div>
    <pre class="text-[11px] bg-gray-900 text-green-400 p-3 rounded-lg whitespace-pre-wrap break-all max-h-48 overflow-y-auto">${msg.rawResponse}</pre>
  </div>`;

  body.innerHTML = html;
  document.getElementById('detailModal').classList.remove('hidden');
}

function hideDetailModal() {
  document.getElementById('detailModal').classList.add('hidden');
}

// ==================== FEEDBACK MODAL ====================
function showFeedbackModal(idx) {
  _feedbackIdx = idx;
  const msg = _chatMessages[idx];
  if (!msg) return;
  document.getElementById('feedbackModalContent').innerHTML = `
    <div class="bg-gray-50 rounded-lg p-3">
      <div class="text-xs text-gray-500 mb-1">Bạn:</div>
      <div class="text-sm text-gray-800 mb-2">${msg.userMessage}</div>
      <div class="text-xs text-gray-500 mb-1">Faye:</div>
      <div class="text-sm text-gray-800">${msg.aiReply}</div>
    </div>`;
  const starsContainer = document.getElementById('feedbackModalStars');
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
  document.getElementById('feedbackModalText').value = msg.feedback || '';
  document.getElementById('feedbackModal').classList.remove('hidden');
}

function hideFeedbackModal() {
  document.getElementById('feedbackModal').classList.add('hidden');
  _feedbackIdx = -1;
}

function saveFeedbackFromModal() {
  if (_feedbackIdx < 0) return;
  const msg = _chatMessages[_feedbackIdx];
  if (!msg) return;
  const starsContainer = document.getElementById('feedbackModalStars');
  const rating = starsContainer.querySelectorAll('.text-amber-400').length;
  msg.rating = rating;
  msg.feedback = document.getElementById('feedbackModalText').value;
  localStorage.setItem('fate_feedback', JSON.stringify(_chatMessages));
  const el = document.getElementById(`stars-${_feedbackIdx}`);
  if (el) el.innerHTML = renderStars(_feedbackIdx, rating);
  hideFeedbackModal();
  showToast('Đã lưu góp ý', 'success');
}

// ==================== FEEDBACK TAB ====================
function renderFeedback() {
  const grid = document.getElementById('feedbackGrid');
  const empty = document.getElementById('feedbackEmpty');
  const withFeedback = _chatMessages.filter(m => m.rating > 0 || m.feedback.trim());
  if (withFeedback.length === 0) {
    grid.innerHTML = '';
    empty.classList.remove('hidden');
    return;
  }
  empty.classList.add('hidden');
  grid.innerHTML = withFeedback.slice().reverse().map((msg, i) => {
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

// ==================== MODEL RATING STARS ====================
function renderModelRating(providerName, modelId) {
  const key = `${providerName}|${modelId}`;
  const current = _modelRatings[key] || 0;
  let s = '';
  for (let i = 1; i <= 5; i++) {
    s += `<span onclick="event.stopPropagation();rateModel('${providerName}','${modelId}',${i})" class="text-sm cursor-pointer ${i <= current ? 'text-amber-400' : 'text-gray-300'} hover:scale-110 transition inline-block" style="line-height:1">★</span>`;
  }
  s += `<span class="text-[10px] text-gray-400 ml-1">${current > 0 ? current + '/5' : ''}</span>`;
  return s;
}

function rateModel(providerName, modelId, stars) {
  const key = `${providerName}|${modelId}`;
  _modelRatings[key] = stars === _modelRatings[key] ? 0 : stars;
  localStorage.setItem('fate_model_ratings', JSON.stringify(_modelRatings));
  // Re-render model selector stars
  const container = document.getElementById('modelRatingContainer');
  if (container) container.innerHTML = renderModelRating(providerName, modelId);
}

// Patch loadModelSelector to include rating
const _origLoadModelSelector = loadModelSelector;
loadModelSelector = async function() {
  await _origLoadModelSelector.call(this);
  const select = document.getElementById('chatModelSelector');
  if (!select) return;
  const updateRating = () => {
    const val = select.value;
    if (!val) { const c = document.getElementById('modelRatingContainer'); if (c) c.innerHTML = ''; return; }
    const [p, m] = val.split('|');
    const c = document.getElementById('modelRatingContainer');
    if (c) c.innerHTML = renderModelRating(p, m);
  };
  select.addEventListener('change', updateRating);
  // Add rating container after select
  if (!document.getElementById('modelRatingContainer')) {
    const wrapper = select.closest('.flex');
    if (wrapper) {
      const el = document.createElement('span');
      el.id = 'modelRatingContainer';
      el.className = 'shrink-0 flex items-center gap-0.5';
      wrapper.appendChild(el);
    }
  }
  updateRating();
};

