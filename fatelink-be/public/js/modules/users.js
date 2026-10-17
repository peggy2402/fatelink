// ==================== USERS MANAGEMENT MODULE ====================

let allUsersData = [];
let filteredUsersData = [];
let currentPage = 1;
let itemsPerPage = 5;
let emotionChartInstance = null;

async function loadUsers() {
  try {
    const res = await authFetch('/admin/users');
    if (res.ok) {
      allUsersData = await res.json();
      filterUsers();
      updateDashboardStats(allUsersData);
    }
  } catch (err) {
    showToast('Lỗi tải danh sách users: ' + err.message, 'error');
  }
}

function updateDashboardStats(users) {
  const totalEl = document.getElementById('statTotalUsers');
  const activeEl = document.getElementById('statActiveUsers');
  const bannedEl = document.getElementById('statBannedUsers');

  if (totalEl) totalEl.innerText = users.length;
  if (activeEl) activeEl.innerText = users.filter(u => !u.isBanned).length;
  if (bannedEl) bannedEl.innerText = users.filter(u => u.isBanned).length;

  const emotions = {};
  users.forEach(u => {
    const emo = u.latestEmotion || 'Chưa cập nhật';
    emotions[emo] = (emotions[emo] || 0) + 1;
  });

  const chartCanvas = document.getElementById('emotionChart');
  if (!chartCanvas) return;

  const ctx = chartCanvas.getContext('2d');
  if (emotionChartInstance) emotionChartInstance.destroy();

  if (typeof Chart !== 'undefined') {
    emotionChartInstance = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: Object.keys(emotions),
        datasets: [{
          data: Object.values(emotions),
          backgroundColor: ['#10b981', '#ef4444', '#f59e0b', '#3b82f6', '#8b5cf6', '#6b7280', '#ec4899'],
          borderWidth: 0,
          cutout: '70%',
        }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'right',
            labels: { boxWidth: 10, font: { size: 11 } },
          },
        },
      },
    });
  }
}

function filterUsers() {
  const filterEl = document.getElementById('userFilter');
  const searchEl = document.getElementById('userSearch');
  const filterValue = filterEl ? filterEl.value : 'all';
  const searchValue = searchEl ? searchEl.value.toLowerCase() : '';

  filteredUsersData = allUsersData.filter(u => {
    const name = (u.name || u.email || 'Người dùng ẩn danh').toLowerCase();
    const matchesSearch = name.includes(searchValue) || (u._id && u._id.includes(searchValue));
    const matchesStatus = filterValue === 'all'
      ? true
      : (filterValue === 'active' ? !u.isBanned : u.isBanned);
    return matchesSearch && matchesStatus;
  });

  currentPage = 1;
  renderPagination();
}

function renderPagination() {
  const totalUsers = filteredUsersData.length;
  const totalPages = Math.ceil(totalUsers / itemsPerPage) || 1;

  const totalEl = document.getElementById('totalUsersDisplay');
  const totalPagesEl = document.getElementById('totalPagesDisplay');
  const currentEl = document.getElementById('currentPageDisplay');
  const prevBtn = document.getElementById('btnPrevPage');
  const nextBtn = document.getElementById('btnNextPage');

  if (totalEl) totalEl.innerText = totalUsers;
  if (totalPagesEl) totalPagesEl.innerText = totalPages;
  if (currentEl) currentEl.innerText = currentPage;
  if (prevBtn) prevBtn.disabled = currentPage === 1;
  if (nextBtn) nextBtn.disabled = currentPage === totalPages;

  const startIdx = (currentPage - 1) * itemsPerPage;
  renderUsers(filteredUsersData.slice(startIdx, startIdx + itemsPerPage));
}

function prevPage() {
  if (currentPage > 1) {
    currentPage--;
    renderPagination();
  }
}

function nextPage() {
  const totalPages = Math.ceil(filteredUsersData.length / itemsPerPage) || 1;
  if (currentPage < totalPages) {
    currentPage++;
    renderPagination();
  }
}

function changeItemsPerPage() {
  const itemsEl = document.getElementById('itemsPerPage');
  if (itemsEl) {
    itemsPerPage = parseInt(itemsEl.value, 10);
  }
  currentPage = 1;
  renderPagination();
}

function renderUsers(users) {
  const tbody = document.getElementById('usersTableBody');
  if (!tbody) return;
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
              <img class="h-10 w-10 rounded-full object-cover shadow-sm" src="${user.avatarUrl || 'https://ui-avatars.com/api/?name='+encodeURIComponent(name)+'&background=0D8ABC&color=fff'}" alt="Avatar">
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
    const res = await authFetch(`/admin/users/${userId}/ban`, {
      method: 'PUT',
      body: JSON.stringify({ isBanned: !currentStatus }),
    });
    if (res.ok) {
      showToast(!currentStatus ? 'Đã khóa tài khoản người dùng' : 'Đã mở khóa tài khoản', 'success');
      loadUsers();
    }
  } catch (err) {
    showToast('Lỗi thực thi lệnh: ' + err.message, 'error');
  }
}
