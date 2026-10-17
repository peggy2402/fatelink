// ==================== FATELINK ADMIN ENTRY POINT ====================

// Khi đã có token, hiển thị ngay Dashboard
if (getAuthToken()) {
  showDashboard();
}

// Xử lý Form đăng nhập Admin
const loginForm = document.getElementById('loginForm');
if (loginForm) {
  loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = document.getElementById('username')?.value.trim();
    const password = document.getElementById('password')?.value;

    try {
      const res = await fetch(`${API_URL}/admin/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });

      if (res.ok) {
        const data = await res.json();
        setAuthToken(data.accessToken);
        showDashboard();
        showToast('Đăng nhập thành công! Chào mừng bạn.', 'success');
        if (typeof addTerminalLog === 'function') {
          addTerminalLog(`Admin [${username}] đã đăng nhập vào hệ thống.`, 'SUCCESS');
        }
      } else {
        showToast('Sai tài khoản hoặc mật khẩu!', 'error');
      }
    } catch (err) {
      showToast('Lỗi kết nối máy chủ', 'error');
    }
  });
}

function logout() {
  setAuthToken(null);
  localStorage.removeItem('admin_last_tab');
  const loginScreen = document.getElementById('loginScreen');
  const dashScreen = document.getElementById('dashboardScreen');
  if (loginScreen) loginScreen.classList.remove('hidden');
  if (dashScreen) dashScreen.classList.add('hidden');
  showToast('Đã đăng xuất', 'warn');
}

function showDashboard() {
  const loginScreen = document.getElementById('loginScreen');
  const dashScreen = document.getElementById('dashboardScreen');
  if (loginScreen) loginScreen.classList.add('hidden');
  if (dashScreen) dashScreen.classList.remove('hidden');

  const savedTab = getSavedTab();
  switchTab(savedTab);
}

// Xử lý gửi tin nhắn Test Chat
const testChatForm = document.getElementById('testChatForm');
if (testChatForm) {
  testChatForm.addEventListener('submit', sendTestChat);
}

// Tải file log server
async function downloadLogs() {
  try {
    const res = await authFetch('/admin/logs/download');
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
      showToast('Chưa có file log', 'warn');
    }
  } catch (e) {
    showToast('Lỗi tải file log', 'error');
  }
}
