function invalid(message) {
  return Object.assign(new Error(message), { status: 400 });
}

function validateRegistration(body = {}) {
  const fullName = typeof body.fullName === 'string' ? body.fullName.trim() : '';
  const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
  const password = typeof body.password === 'string' ? body.password : '';
  const phone = typeof body.phone === 'string' ? body.phone.trim() : null;
  if (fullName.length < 2 || fullName.length > 120) throw invalid('Name must be 2 to 120 characters.');
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254) throw invalid('Enter a valid email address.');
  if (password.length < 10 || password.length > 72) throw invalid('Password must be 10 to 72 characters.');
  if (phone && phone.length > 30) throw invalid('Phone number is too long.');
  return { fullName, email, password, phone };
}

function validateOrder(body = {}) {
  const restaurantId = Number(body.restaurantId);
  const deliveryAddress = typeof body.deliveryAddress === 'string' ? body.deliveryAddress.trim() : '';
  const items = body.items;
  if (!Number.isSafeInteger(restaurantId) || restaurantId < 1) throw invalid('Choose a valid restaurant.');
  if (deliveryAddress.length < 5 || deliveryAddress.length > 300) throw invalid('Enter a delivery address between 5 and 300 characters.');
  if (!Array.isArray(items) || items.length < 1 || items.length > 30) throw invalid('Your cart must contain 1 to 30 items.');
  const normalized = items.map((item) => ({ foodItemId: Number(item.foodItemId), quantity: Number(item.quantity) }));
  if (normalized.some((item) => !Number.isSafeInteger(item.foodItemId) || item.foodItemId < 1 || !Number.isSafeInteger(item.quantity) || item.quantity < 1 || item.quantity > 50)) {
    throw invalid('Each item needs a valid ID and quantity from 1 to 50.');
  }
  if (new Set(normalized.map((item) => item.foodItemId)).size !== normalized.length) throw invalid('Cart item IDs must be unique.');
  return { restaurantId, deliveryAddress, items: normalized };
}

module.exports = { validateRegistration, validateOrder };