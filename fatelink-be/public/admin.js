const API_URL = '/api';
let token = localStorage.getItem('admin_token');
let _statusCache = {};

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

  ['configTab', 'usersTab', 'modelsTab', 'testChatTab'].forEach(id => {
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
  let modelId = '';
  let providerName = '';
  if (selectedVal) {
    [providerName, modelId] = selectedVal.split('|');
  }

  const chatBox = document.getElementById('chatBox');
  const modelLabel = select && select.selectedOptions[0]
    ? select.selectedOptions[0].textContent.trim()
    : 'Theo thứ tự ưu tiên';
  chatBox.innerHTML += `<div class="text-right mb-4"><span class="bg-blue-600 text-white px-4 py-2 rounded-xl inline-block shadow-sm">${message}</span></div>`;
  chatBox.innerHTML += `<div id="typing" class="text-left mb-4"><span class="bg-gray-200 text-gray-500 px-4 py-2 rounded-xl inline-block animate-pulse">AI đang phân tích <small class="text-gray-400 ml-2">(${modelLabel})</small>...</span></div>`;
  chatBox.scrollTop = chatBox.scrollHeight;

  try {
    const body = { message };
    if (modelId && providerName) {
      body.modelId = modelId;
      body.providerName = providerName;
    }
    const res = await fetch(`${API_URL}/admin/ai-chat`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    document.getElementById('typing').remove();
    const textResponse = await res.text();
    let parsed = null;
    try { parsed = JSON.parse(textResponse); } catch(e) {}

    if (parsed && parsed.reply) {
      chatBox.innerHTML += `<div class="text-left mb-4">
        <div class="inline-block max-w-full">
          <div class="bg-white border border-gray-200 px-4 py-2 rounded-xl text-gray-800 shadow-sm">${parsed.reply.replace(/\n/g, '<br>')}</div>
          <div class="mt-1 text-[10px] text-gray-400 px-2">Dùng: ${modelLabel}</div>
          <pre class="text-[11px] bg-gray-900 text-green-400 p-3 mt-2 rounded-lg overflow-x-auto">Dữ liệu bóc tách (JSON):\n${textResponse}</pre>
        </div>
      </div>`;
    } else {
      chatBox.innerHTML += `<div class="text-left mb-4">
        <div class="inline-block max-w-full">
          <pre class="text-[11px] bg-gray-900 text-yellow-400 p-3 rounded-lg overflow-x-auto shadow-sm">${textResponse}</pre>
          <div class="mt-1 text-[10px] text-gray-400 px-2">Dùng: ${modelLabel}</div>
        </div>
      </div>`;
    }
    chatBox.scrollTop = chatBox.scrollHeight;
  } catch (err) {
    if (document.getElementById('typing')) document.getElementById('typing').remove();
    showToast('Lỗi gửi tin nhắn', 'error');
  }
}

function clearChat() {
  document.getElementById('chatBox').innerHTML = '<div class="text-center text-gray-400 italic mt-10">Lịch sử chat đã được xóa.</div>';
}
