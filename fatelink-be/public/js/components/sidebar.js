// ==================== SIDEBAR & NAVIGATION COMPONENT ====================
function getSavedTab() {
  return localStorage.getItem('admin_last_tab') || 'systemConfigTab';
}

function saveActiveTab(tabId) {
  localStorage.setItem('admin_last_tab', tabId);
}

function toggleSidebar() {
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('sidebarOverlay');
  if (sidebar) sidebar.classList.toggle('-translate-x-full');
  if (overlay) overlay.classList.toggle('hidden');
}

const TAB_CONFIGS = {
  systemConfigTab: {
    title: 'Cấu hình hệ thống & Mạng xã hội',
    loader: () => typeof loadSystemConfig === 'function' && loadSystemConfig(),
  },
  configTab: {
    title: 'Cấu hình AI',
    loader: () => typeof loadConfig === 'function' && loadConfig(),
  },
  usersTab: {
    title: 'Quản lý Users',
    loader: () => typeof loadUsers === 'function' && loadUsers(),
  },
  modelsTab: {
    title: 'Quản lý AI Models',
    loader: () => typeof loadAiModels === 'function' && loadAiModels(),
  },
  testChatTab: {
    title: 'Test AI Chat',
    loader: () => {
      if (typeof loadModelSelector === 'function') loadModelSelector();
      if (typeof renderFateInsight === 'function') renderFateInsight();
    },
  },
  feedbackTab: {
    title: 'Góp ý AI',
    loader: () => typeof renderFeedback === 'function' && renderFeedback(),
  },
};

function switchTab(tabId) {
  const allTabs = Object.keys(TAB_CONFIGS);

  // 1. Ẩn tất cả các tab
  allTabs.forEach(id => {
    const el = document.getElementById(id);
    if (el) el.classList.add('hidden');
    const btn = document.getElementById(`btn-${id}`);
    if (btn) {
      btn.classList.remove('bg-gray-800', 'text-white');
      btn.classList.add('text-gray-400');
    }
  });

  // 2. Hiện tab được chọn
  const activeEl = document.getElementById(tabId);
  if (activeEl) activeEl.classList.remove('hidden');

  const activeBtn = document.getElementById(`btn-${tabId}`);
  if (activeBtn) {
    activeBtn.classList.remove('text-gray-400');
    activeBtn.classList.add('bg-gray-800', 'text-white');
  }

  saveActiveTab(tabId);

  // 3. Cập nhật Title và gọi loader tương ứng
  const tabInfo = TAB_CONFIGS[tabId] || TAB_CONFIGS['systemConfigTab'];
  const titleEl = document.getElementById('pageTitle');
  if (titleEl) titleEl.innerText = tabInfo.title;

  if (tabInfo.loader) {
    tabInfo.loader();
  }

  // 4. Đóng sidebar trên mobile
  if (window.innerWidth < 768) {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebarOverlay');
    if (sidebar) sidebar.classList.add('-translate-x-full');
    if (overlay) overlay.classList.add('hidden');
  }
}
