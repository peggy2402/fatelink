// ==================== CORE API & AUTHENTICATION ====================
const API_URL = '/api';
let token = localStorage.getItem('admin_token');

function getAuthToken() {
  return token || localStorage.getItem('admin_token');
}

function setAuthToken(newToken) {
  token = newToken;
  if (newToken) {
    localStorage.setItem('admin_token', newToken);
  } else {
    localStorage.removeItem('admin_token');
  }
}

/**
 * Wrapper gọi API có tự động đính kèm Authorization Header
 * Tự động logout nếu phiên làm việc hết hạn (401)
 */
async function authFetch(url, options = {}) {
  const currentToken = getAuthToken();
  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };

  if (currentToken) {
    headers['Authorization'] = `Bearer ${currentToken}`;
  }

  const response = await fetch(url.startsWith('http') ? url : `${API_URL}${url}`, {
    ...options,
    headers,
  });

  if (response.status === 401) {
    if (typeof logout === 'function') {
      logout();
    }
    throw new Error('Phiên đăng nhập đã hết hạn');
  }

  return response;
}
