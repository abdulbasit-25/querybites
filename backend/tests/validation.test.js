const test = require('node:test');
const assert = require('node:assert/strict');

const { validateRegistration, validateOrder } = require('../src/utils/validation');

test('validateRegistration accepts a valid registration payload', () => {
  const value = validateRegistration({
    fullName: 'Ayesha Khan',
    email: 'ayesha@example.com',
    password: 'verysecurepass',
    phone: '03001234567'
  });

  assert.equal(value.fullName, 'Ayesha Khan');
  assert.equal(value.email, 'ayesha@example.com');
  assert.equal(value.phone, '03001234567');
});

test('validateRegistration rejects weak input', () => {
  assert.throws(() => validateRegistration({ fullName: 'A', email: 'bad', password: 'short' }), /valid email|Name must be 2 to 120 characters|Password must be 10 to 72 characters/);
});

test('validateOrder rejects duplicate item IDs and invalid quantities', () => {
  assert.throws(() => validateOrder({
    restaurantId: 1,
    deliveryAddress: '123 Main Street',
    items: [
      { foodItemId: 10, quantity: 2 },
      { foodItemId: 10, quantity: 1 }
    ]
  }), /Cart item IDs must be unique/);

  assert.throws(() => validateOrder({
    restaurantId: 1,
    deliveryAddress: '123 Main Street',
    items: [{ foodItemId: 3, quantity: 0 }]
  }), /Each item needs a valid ID and quantity/);
});
