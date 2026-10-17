// ==================== SYSTEM & SOCIAL AUTH CONFIG MODULE ====================

let _currentSystemConfig = {};

async function loadSystemConfig() {
  try {
    const res = await authFetch('/admin/config');
    if (!res.ok) throw new Error('Không thể tải cấu hình hệ thống');

    const data = await res.json();
    _currentSystemConfig = data;

    const social = data.socialAuth || {};

    // 1. Facebook
    const fb = social.facebook || {};
    const fbToggle = document.getElementById('fb_enabled');
    if (fbToggle) fbToggle.checked = fb.enabled !== false;
    const fbAppId = document.getElementById('fb_appId');
    if (fbAppId) fbAppId.value = fb.appId || '';
    const fbClientToken = document.getElementById('fb_clientToken');
    if (fbClientToken) fbClientToken.value = fb.clientToken || '';
    const fbAppSecret = document.getElementById('fb_appSecret');
    if (fbAppSecret) fbAppSecret.value = fb.appSecret || '';

    // 2. Google
    const gg = social.google || {};
    const ggToggle = document.getElementById('gg_enabled');
    if (ggToggle) ggToggle.checked = gg.enabled !== false;
    const ggClientId = document.getElementById('gg_clientId');
    if (ggClientId) ggClientId.value = gg.clientId || '';
    const ggIosClientId = document.getElementById('gg_iosClientId');
    if (ggIosClientId) ggIosClientId.value = gg.iosClientId || '';

    // 3. Zalo
    const zalo = social.zalo || {};
    const zaloToggle = document.getElementById('zalo_enabled');
    if (zaloToggle) zaloToggle.checked = zalo.enabled !== false;
    const zaloAppId = document.getElementById('zalo_appId');
    if (zaloAppId) zaloAppId.value = zalo.appId || '';
    const zaloSecretKey = document.getElementById('zalo_secretKey');
    if (zaloSecretKey) zaloSecretKey.value = zalo.secretKey || '';

    // 4. TikTok
    const tt = social.tiktok || {};
    const ttToggle = document.getElementById('tt_enabled');
    if (ttToggle) ttToggle.checked = tt.enabled !== false;
    const ttClientKey = document.getElementById('tt_clientKey');
    if (ttClientKey) ttClientKey.value = tt.clientKey || '';
    const ttClientSecret = document.getElementById('tt_clientSecret');
    if (ttClientSecret) ttClientSecret.value = tt.clientSecret || '';

    // 5. Cài đặt chung
    const messageLimit = document.getElementById('sys_onboardingMessageLimit');
    if (messageLimit) messageLimit.value = data.onboardingMessageLimit || 10;

  } catch (err) {
    showToast('Lỗi khi tải cấu hình hệ thống: ' + err.message, 'error');
  }
}

async function saveSystemConfig() {
  const saveBtn = document.getElementById('btnSaveSystemConfig');
  const originalBtnText = saveBtn ? saveBtn.innerHTML : '';

  try {
    if (saveBtn) {
      saveBtn.disabled = true;
      saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i> Đang lưu...';
    }

    const payload = {
      ..._currentSystemConfig,
      onboardingMessageLimit: parseInt(document.getElementById('sys_onboardingMessageLimit')?.value || '10', 10),
      socialAuth: {
        facebook: {
          enabled: document.getElementById('fb_enabled')?.checked ?? true,
          appId: document.getElementById('fb_appId')?.value.trim() || '',
          clientToken: document.getElementById('fb_clientToken')?.value.trim() || '',
          appSecret: document.getElementById('fb_appSecret')?.value.trim() || '',
        },
        google: {
          enabled: document.getElementById('gg_enabled')?.checked ?? true,
          clientId: document.getElementById('gg_clientId')?.value.trim() || '',
          iosClientId: document.getElementById('gg_iosClientId')?.value.trim() || '',
        },
        zalo: {
          enabled: document.getElementById('zalo_enabled')?.checked ?? true,
          appId: document.getElementById('zalo_appId')?.value.trim() || '',
          secretKey: document.getElementById('zalo_secretKey')?.value.trim() || '',
        },
        tiktok: {
          enabled: document.getElementById('tt_enabled')?.checked ?? true,
          clientKey: document.getElementById('tt_clientKey')?.value.trim() || '',
          clientSecret: document.getElementById('tt_clientSecret')?.value.trim() || '',
        },
      },
    };

    const res = await authFetch('/admin/config', {
      method: 'PUT',
      body: JSON.stringify(payload),
    });

    if (res.ok) {
      _currentSystemConfig = await res.json();
      showToast('Đã lưu cấu hình hệ thống & mạng xã hội thành công! ✨', 'success');
      if (typeof addTerminalLog === 'function') {
        addTerminalLog('Cập nhật cấu hình Social Auth (Facebook, Google, Zalo, TikTok) thành công', 'SUCCESS');
      }
    } else {
      throw new Error('Lỗi từ máy chủ (' + res.status + ')');
    }
  } catch (err) {
    showToast('Không thể lưu cấu hình: ' + err.message, 'error');
  } finally {
    if (saveBtn) {
      saveBtn.disabled = false;
      saveBtn.innerHTML = originalBtnText;
    }
  }
}

function toggleSecretVisibility(inputId, btnEl) {
  const input = document.getElementById(inputId);
  if (!input) return;

  if (input.type === 'password') {
    input.type = 'text';
    btnEl.innerHTML = '<i class="fas fa-eye-slash"></i>';
  } else {
    input.type = 'password';
    btnEl.innerHTML = '<i class="fas fa-eye"></i>';
  }
}

function copyFieldValue(inputId, labelName) {
  const input = document.getElementById(inputId);
  if (!input || !input.value) {
    showToast(`Chưa có giá trị để sao chép cho ${labelName}`, 'warn');
    return;
  }
  navigator.clipboard.writeText(input.value);
  showToast(`Đã sao chép ${labelName} vào Clipboard!`, 'success');
}
