import { api, setNotice, formatMoney } from './api.js';

const metricsRow = document.querySelector('#admin-metrics');
const adminOrders = document.querySelector('#admin-orders');
const notice = document.querySelector('[data-notice]');
const refreshButton = document.querySelector('#refresh-admin');

function statusClass(status) {
  const value = (status || '').toLowerCase();
  if (value.includes('cancel')) return 'status-badge status-badge--cancelled';
  if (value.includes('pending') || value.includes('await')) return 'status-badge status-badge--pending';
  if (value.includes('in transit') || value.includes('delivery')) return 'status-badge status-badge--in-transit';
  if (value.includes('failed')) return 'status-badge status-badge--failed';
  return 'status-badge';
}

function renderMetrics(metrics = {}) {
  if (!metricsRow) return;
  const cards = [
    { label: 'Active orders', value: metrics.ActiveOrders ?? 0 },
    { label: 'Low stock', value: metrics.LowStockItems ?? 0 },
    { label: 'Restaurants', value: metrics.ActiveRestaurants ?? 0 }
  ];

  metricsRow.innerHTML = '';
  cards.forEach((card) => {
    const wrapper = document.createElement('div');
    wrapper.className = 'metric-card';

    const label = document.createElement('span');
    label.className = 'metric-card__label';
    label.textContent = card.label;

    const value = document.createElement('span');
    value.className = 'metric-card__value';
    value.textContent = String(card.value);

    wrapper.append(label, value);
    metricsRow.appendChild(wrapper);
  });
}

function renderAdminOrders(orders = []) {
  if (!adminOrders) return;
  adminOrders.innerHTML = '';

  if (!orders.length) {
    const empty = document.createElement('p');
    empty.className = 'empty-copy';
    empty.textContent = 'No recent orders found.';
    adminOrders.appendChild(empty);
    return;
  }

  orders.forEach((order) => {
    const card = document.createElement('article');
    card.className = 'admin-order-card';

    const body = document.createElement('div');
    body.className = 'admin-order-card__body';

    const top = document.createElement('div');
    top.className = 'restaurant-card__meta';

    const title = document.createElement('h3');
    title.textContent = `Order #${order.OrderID || order.orderId}`;

    const badge = document.createElement('span');
    badge.className = statusClass(order.Status || order.status);
    badge.textContent = order.Status || order.status || 'Pending';

    top.append(title, badge);

    const customer = document.createElement('p');
    customer.textContent = `Customer ID: ${order.CustomerID || order.customerId}`;

    const summary = document.createElement('p');
    summary.textContent = `Restaurant ${order.RestaurantID || order.restaurantId} • ${new Date(order.CreatedAtUtc || Date.now()).toLocaleString()}`;

    const total = document.createElement('strong');
    total.textContent = formatMoney(order.TotalAmount || 0);

    const action = document.createElement('button');
    action.type = 'button';
    action.className = 'button button--outline button--small';
    action.textContent = 'Refresh';
    action.addEventListener('click', loadAdminSummary);

    body.append(top, customer, summary, total, action);
    card.append(body);
    adminOrders.appendChild(card);
  });
}

async function loadAdminSummary() {
  try {
    const { metrics = {}, orders = [] } = await api('/admin/summary');
    renderMetrics(metrics);
    renderAdminOrders(orders);
  } catch (error) {
    setNotice(notice, error.message, 'error');
  }
}

(async () => {
  try {
    await api('/auth/me');
    await loadAdminSummary();
  } catch (error) {
    setNotice(notice, error.message, 'error');
    window.location.href = './login.html';
  }
})();

refreshButton?.addEventListener('click', loadAdminSummary);
