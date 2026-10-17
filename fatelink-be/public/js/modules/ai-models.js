// ==================== AI MODELS MODULE ====================

let allModelsData = [];
let filteredModelsData = [];
let _statusCache = {};
let _priorityTargetModel = null;

try {
  const cached = sessionStorage.getItem('ai_status_cache');
  if (cached) _statusCache = JSON.parse(cached);
} catch (e) {}

const modelModal = document.getElementById('modelModal');
const modelForm = document.getElementById('modelForm');

function showModelModal(model) {
  if (!modelForm) return;
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
  if (modelModal) modelModal.classList.remove('hidden');
}

function hideModelModal() {
  if (modelModal) modelModal.classList.add('hidden');
}

if (modelForm) {
  modelForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('modelIdField')?.value;
    const existingModel = allModelsData.find(m => m.id === id);
    const dto = {
      displayName: document.getElementById('displayName')?.value,
      providerName: document.getElementById('providerName')?.value,
      modelId: document.getElementById('modelIdentifier')?.value,
      isEnabled: true,
      priority: existingModel && existingModel.priority !== undefined ? existingModel.priority : 0,
    };
    const url = id ? `/admin/models/${id}` : `/admin/models`;
    const method = id ? 'PUT' : 'POST';
    try {
      const res = await authFetch(url, {
        method,
        body: JSON.stringify(dto),
      });
      if (res.ok) {
        showToast(id ? 'Cập nhật thành công!' : 'Thêm model thành công!', 'success');
        if (typeof addTerminalLog === 'function') {
          addTerminalLog(`Đã ${id ? 'cập nhật' : 'thêm mới'} Model <b class="text-white">${dto.displayName}</b> (${dto.modelId}) của nhà cung cấp ${dto.providerName}.`, 'SUCCESS');
        }
        hideModelModal();
        loadAiModels();
      } else {
        const errData = await res.json().catch(() => ({}));
        let errMsg = errData.message || 'Dữ liệu không hợp lệ hoặc Model ID đã tồn tại!';
        if (Array.isArray(errMsg)) errMsg = errMsg.join(', ');
        showToast(`Lỗi: ${errMsg}`, 'error');
      }
    } catch (err) {
      showToast('Lỗi thực thi: ' + err.message, 'error');
    }
  });
}

async function loadAiModels() {
  try {
    const res = await authFetch('/admin/models');
    if (res.ok) {
      allModelsData = await res.json();
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
  const filterEl = document.getElementById('modelFilter');
  const providerEl = document.getElementById('providerFilter');
  const searchEl = document.getElementById('modelSearch');

  const filterValue = filterEl ? filterEl.value : 'all';
  const providerValue = providerEl ? providerEl.value : 'all';
  const searchValue = searchEl ? searchEl.value.toLowerCase() : '';

  filteredModelsData = allModelsData.filter(m => {
    const textStr = (m.displayName + ' ' + m.modelId + ' ' + m.providerName).toLowerCase();
    const matchesSearch = textStr.includes(searchValue);
    const isEnabled = m.isEnabled !== false;
    const matchesStatus = filterValue === 'all' ? true : (filterValue === 'enabled' ? isEnabled : !isEnabled);
    const matchesProvider = providerValue === 'all' ? true : m.providerName === providerValue;
    return matchesSearch && matchesStatus && matchesProvider;
  });
  renderModels(filteredModelsData);
}

function renderModels(models) {
  const grid = document.getElementById('modelsCardGrid');
  const empty = document.getElementById('modelsEmptyState');
  if (!grid) return;
  grid.innerHTML = '';
  if (models.length === 0) {
    if (empty) empty.classList.remove('hidden');
    return;
  }
  if (empty) empty.classList.add('hidden');
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

function showPriorityModal(model) {
  _priorityTargetModel = model;
  const nameEl = document.getElementById('priorityModalModelName');
  if (nameEl) nameEl.innerHTML = `<b>${model.displayName}</b><br><span class="text-gray-400">${model.providerName} - ${model.modelId}</span>`;
  const modalEl = document.getElementById('priorityModal');
  if (modalEl) modalEl.classList.remove('hidden');
}

function hidePriorityModal() {
  const modalEl = document.getElementById('priorityModal');
  if (modalEl) modalEl.classList.add('hidden');
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
    const res = await authFetch('/admin/models/reorder', {
      method: 'PUT',
      body: JSON.stringify({ modelIds: allIds }),
    });
    if (res.ok) {
      showToast(zone === 'primary' ? `✅ ${model.displayName} là Model ưu tiên #1!` : `✅ ${model.displayName} là Model fallback!`, 'success');
      await loadAiModels();
    }
  } catch (e) {
    showToast('Lỗi khi thiết lập thứ tự ưu tiên', 'error');
  }
}

async function toggleAiModel(id, currentStatus) {
  try {
    await authFetch(`/admin/models/${id}`, {
      method: 'PUT',
      body: JSON.stringify({ isEnabled: !currentStatus }),
    });
    showToast(!currentStatus ? 'Đã BẬT Model!' : 'Đã TẮT Model!', 'success');
    if (typeof addTerminalLog === 'function') {
      addTerminalLog(`Hệ thống đã ${!currentStatus ? 'KÍCH HOẠT' : 'VÔ HIỆU HÓA'} model (ID Database: ${id})`, 'WARN');
    }
    loadAiModels();
  } catch (e) {
    showToast('Lỗi khi đổi trạng thái model', 'error');
  }
}

async function deleteAiModel(id) {
  if (!confirm('Bạn có chắc muốn xóa model này?')) return;
  try {
    await authFetch(`/admin/models/${id}`, { method: 'DELETE' });
    showToast('Xóa model thành công!', 'success');
    if (typeof addTerminalLog === 'function') {
      addTerminalLog(`Đã xóa vĩnh viễn model khỏi cơ sở dữ liệu (ID: ${id})`, 'WARN');
    }
    loadAiModels();
  } catch (err) {
    showToast('Lỗi khi xóa', 'error');
  }
}

async function checkAiModels() {
  const btn = document.getElementById('btnCheckAi');
  const btnText = document.getElementById('btnCheckAiText');
  const container = document.getElementById('aiStatusContainer');
  if (btn) btn.disabled = true;
  if (btnText) btnText.innerText = 'Đang quét...';
  if (container) container.innerHTML = '<p class="text-blue-400 animate-pulse">> Đang gửi gói tin ping đến các máy chủ AI, vui lòng chờ...</p>';
  allModelsData.forEach(model => { model._apiStatus = { status: 'LOADING' }; });
  renderModels(filteredModelsData);

  try {
    const res = await authFetch('/admin/ai-status');
    if (res.ok) {
      const statuses = await res.json();
      if (container) container.innerHTML = '';
      const groupedData = statuses.reduce((acc, current) => {
        const provider = current.provider || 'Unknown Provider';
        if (!acc[provider]) acc[provider] = [];
        if (current.modelId || current.displayName) acc[provider].push(current);
        return acc;
      }, {});
      if (typeof addTerminalLog === 'function') {
        addTerminalLog(`=== BÁO CÁO TRẠNG THÁI AI PROVIDERS ===`, 'INFO');
        for (const [provider, models] of Object.entries(groupedData)) {
          addTerminalLog(`📦 Provider: <b class="text-white">${provider}</b>`, 'INFO');
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
      });
      sessionStorage.setItem('ai_status_cache', JSON.stringify(_statusCache));
      renderModels(filteredModelsData);
      renderPriorityZones();
    }
  } catch (err) {
    showToast('Lỗi khi kiểm tra trạng thái AI', 'error');
  } finally {
    if (btn) btn.disabled = false;
    if (btnText) btnText.innerText = 'Cập nhật trạng thái';
  }
}

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
