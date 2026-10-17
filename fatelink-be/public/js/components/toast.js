// ==================== TOAST COMPONENT ====================
function showToast(msg, type = 'success') {
  const toast = document.getElementById('toast');
  const toastMsg = document.getElementById('toastMsg');
  const icon = document.getElementById('toastIcon');

  if (!toast || !toastMsg || !icon) return;

  toastMsg.innerText = msg;
  icon.className = type === 'success'
    ? 'fas fa-check-circle text-green-400 w-5'
    : (type === 'warn' ? 'fas fa-exclamation-triangle text-yellow-400 w-5' : 'fas fa-exclamation-circle text-red-400 w-5');

  toast.classList.remove('translate-y-20', 'opacity-0');
  
  if (window._toastTimeout) clearTimeout(window._toastTimeout);
  window._toastTimeout = setTimeout(() => {
    toast.classList.add('translate-y-20', 'opacity-0');
  }, 3200);
}
