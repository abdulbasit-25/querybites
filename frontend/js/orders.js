import { api, setNotice, formatMoney } from './api.js';

const notice = document.querySelector('[data-notice]');
const ordersList = document.querySelector('#orders-list');

function statusClass(status) {
  const value = (status || '').toLowerCase();
  if (value.includes('cancel') || value.includes('failed')) return 'status-badge status-badge--cancelled';
  if (value.includes('pending') || value.includes('await')) return 'status-badge status-badge--pending';
  if (value.includes('in transit') || value.includes('delivery')) return 'status-badge status-badge--in-transit';
  return 'status-badge';
}

function escapeText(value) {
  return String(value ?? '');
}

function renderOrders(orders = []) {
  if (!ordersList) return;
  ordersList.innerHTML = '';

  if (!orders.length) {
    const empty = document.createElement('p');
    empty.className = 'empty-copy';
    empty.textContent = 'You have not placed any orders yet.';
    ordersList.appendChild(empty);
    return;
  }

  orders.forEach((order) => {
    const card = document.createElement('article');
    card.className = 'order-card';

    const body = document.createElement('div');
    body.className = 'order-card__body';

    const top = document.createElement('div');
    top.className = 'restaurant-card__meta';

    const title = document.createElement('h3');
    title.textContent = `Order #${order.OrderID || order.orderId}`;

    const badge = document.createElement('span');
    badge.className = statusClass(order.Status || order.status);
    badge.textContent = order.Status || order.status || 'Pending';

    top.append(title, badge);

    const meta = document.createElement('div');
    meta.className = 'order-card__meta';
    const created = document.createElement('span');
    created.textContent = order.CreatedAtUtc ? new Date(order.CreatedAtUtc).toLocaleString() : 'Today';
    const total = document.createElement('strong');
    total.textContent = formatMoney(order.TotalAmount || 0);
    meta.append(created, total);

    const items = document.createElement('div');
    items.className = 'order-card__items';
    const itemSummary = Array.isArray(order.Items) && order.Items.length ? order.Items.map((item) => `${item.Name || 'Item'} x ${item.Quantity || 1}`).join(', ') : 'No details available';
    items.textContent = itemSummary;

    const footer = document.createElement('div');
    footer.className = 'order-card__meta';

    const address = document.createElement('span');
    address.textContent = order.DeliveryAddress || order.deliveryAddress || 'Delivery to your address';

    const actionButton = document.createElement('button');
    actionButton.type = 'button';
    actionButton.className = 'button button--outline button--small';
    actionButton.textContent = 'Cancel';
    actionButton.disabled = ['cancelled', 'delivered', 'payment_failed'].includes((order.Status || '').toLowerCase());
    actionButton.addEventListener('click', async () => {
      try {
        await api(`/orders/${order.OrderID || order.orderId}/cancel`, { method: 'POST' });
        await loadOrders();
      } catch (error) {
        setNotice(notice, error.message, 'error');
      }
    });

    footer.append(address, actionButton);
    body.append(top, meta, items, footer);
    card.append(body);
    ordersList.appendChild(card);
  });
}

async function loadOrders() {
  const { orders = [] } = await api('/orders');
  renderOrders(orders);
}

(async () => {
  try {
    await api('/auth/me');
    await loadOrders();
  } catch (error) {
    setNotice(notice, error.message, 'error');
    window.location.href = './login.html';
  }
})();
