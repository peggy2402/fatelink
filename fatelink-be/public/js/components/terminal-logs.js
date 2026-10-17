// ==================== TERMINAL LOGS COMPONENT ====================
function addTerminalLog(message, type = 'INFO') {
  const container = document.getElementById('aiStatusContainer');
  if (!container) return;

  const time = new Date().toLocaleTimeString('vi-VN');
  let colorClass = 'text-blue-400';
  if (type === 'SUCCESS') colorClass = 'text-green-400';
  if (type === 'ERROR') colorClass = 'text-red-400';
  if (type === 'WARN') colorClass = 'text-yellow-400';

  const placeholder = container.querySelector('.italic');
  if (placeholder) placeholder.remove();

  container.innerHTML += `<p class="border-l-2 border-gray-600 pl-3"><span class="${colorClass} font-bold">[${time}] [${type}]</span> <span class="text-gray-300 ml-1 leading-relaxed">${message}</span></p>`;
  container.scrollTop = container.scrollHeight;

  // Ghi nhận log về backend nếu có kết nối
  authFetch('/admin/logs', {
    method: 'POST',
    body: JSON.stringify({ message, type }),
  }).catch(() => {});
}

function clearTerminalLogs() {
  const container = document.getElementById('aiStatusContainer');
  if (container) {
    container.innerHTML = '<p class="text-gray-500 italic">Đã dọn dẹp hệ thống logs. Sẵn sàng ghi nhận mới...</p>';
  }
}
