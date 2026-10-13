import { api, setNotice, formatMoney } from './api.js';

const state = {
  restaurants: [],
  foods: [],
  cart: loadCart()
};

const restaurantGrid = document.querySelector('#restaurant-grid');
const restaurantSearchForm = document.querySelector('#restaurant-search');
const restaurantQuery = document.querySelector('#restaurant-query');
const foodGrid = document.querySelector('#food-grid');
const restaurantFilter = document.querySelector('#restaurant-filter');
const categoryFilter = document.querySelector('#category-filter');
const maxPriceInput = document.querySelector('#max-price');
const foodSearchInput = document.querySelector('#food-search');
const foodSearchButton = document.querySelector('#food-search-button');
const resultCount = document.querySelector('#result-count');
const cartItems = document.querySelector('#cart-items');
const cartTotal = document.querySelector('#cart-total');
const cartCount = document.querySelector('#cart-count');
const checkoutForm = document.querySelector('#checkout-form');
const checkoutNotice = document.querySelector('#checkout-notice');
const pageNotice = document.querySelector('[data-notice]');

function loadCart() {
  try {
    const raw = localStorage.getItem('foodbot-cart');
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function persistCart() {
  localStorage.setItem('foodbot-cart', JSON.stringify(state.cart));
}

function coalesce(value, fallback) {
  return value ?? fallback;
}

function getFoodId(item) {
  return Number(coalesce(item.FoodItemID, item.foodItemId, item.id));
}

function getRestaurantId(item) {
  return Number(coalesce(item.RestaurantID, item.restaurantId, item.restaurant_id));
}

function ensureLoggedIn() {
  return api('/auth/me').catch(() => {
    window.location.href = './login.html';
    return null;
  });
}

function createFallbackCard(message) {
  const card = document.createElement('div');
  card.className = 'restaurant-card';
  const body = document.createElement('div');
  body.className = 'restaurant-card__body';
  const text = document.createElement('p');
  text.textContent = message;
  body.append(text);
  card.append(body);
  return card;
}

function renderRestaurants(items = []) {
  if (!restaurantGrid) return;
  restaurantGrid.innerHTML = '';
  if (!items.length) {
    restaurantGrid.appendChild(createFallbackCard('No matching kitchens right now.'));
    return;
  }

  items.forEach((restaurant) => {
    const card = document.createElement('article');
    card.className = 'restaurant-card';

    const image = document.createElement('div');
    image.className = 'restaurant-card__image';
    image.style.backgroundImage = `linear-gradient(180deg, rgba(19, 17, 15, 0.06), rgba(19, 17, 15, 0.2)), url(${restaurant.ImageUrl || 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=900&q=80'})`;

    const body = document.createElement('div');
    body.className = 'restaurant-card__body';

    const meta = document.createElement('div');
    meta.className = 'restaurant-card__meta';

    const title = document.createElement('h3');
    title.textContent = restaurant.Name || 'Neighborhood kitchen';

    const rating = document.createElement('span');
    rating.className = 'status-badge';
    rating.textContent = `${Number(restaurant.Rating || 4.5).toFixed(1)}★`;
    meta.append(title, rating);

    const description = document.createElement('p');
    description.textContent = restaurant.Description || 'Fresh, local favorites ready to deliver.';

    const footer = document.createElement('div');
    footer.className = 'restaurant-card__meta';

    const cuisine = document.createElement('span');
    cuisine.textContent = restaurant.CuisineType || 'Mix of classics';
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'button button--outline button--small';
    button.textContent = 'View menu';
    button.addEventListener('click', () => {
      if (restaurantFilter) {
        restaurantFilter.value = String(restaurant.RestaurantID || restaurant.restaurantId || '');
      }
      if (window.location.pathname.endsWith('menu.html')) {
        loadFoods();
        window.scrollTo({ top: 0, behavior: 'smooth' });
      } else {
        window.location.href = `./menu.html?restaurant=${restaurant.RestaurantID || restaurant.restaurantId}`;
      }
    });

    footer.append(cuisine, button);
    body.append(meta, description, footer);
    card.append(image, body);
    restaurantGrid.append(card);
  });
}

function renderFoods() {
  if (!foodGrid) return;
  const searchTerm = (foodSearchInput?.value || '').trim().toLowerCase();
  const restaurantValue = restaurantFilter ? restaurantFilter.value : '';
  const categoryValue = categoryFilter ? categoryFilter.value : '';
  const maxPriceValue = maxPriceInput ? Number(maxPriceInput.value || 0) : 0;

  const filtered = state.foods.filter((item) => {
    const text = `${item.Name || ''} ${item.Description || ''}`.toLowerCase();
    const matchesQuery = !searchTerm || text.includes(searchTerm);
    const matchesRestaurant = !restaurantValue || String(getRestaurantId(item)) === String(restaurantValue);
    const matchesCategory = !categoryValue || (item.CategoryName || item.Category || '').toLowerCase() === categoryValue.toLowerCase();
    const matchesPrice = !maxPriceValue || Number(item.Price || 0) <= maxPriceValue;
    return matchesQuery && matchesRestaurant && matchesCategory && matchesPrice;
  });

  foodGrid.innerHTML = '';
  if (resultCount) resultCount.textContent = `${filtered.length}`;

  if (!filtered.length) {
    const empty = document.createElement('p');
    empty.className = 'empty-copy';
    empty.textContent = 'No dishes match that search right now.';
    foodGrid.appendChild(empty);
    return;
  }

  filtered.forEach((item) => {
    const card = document.createElement('article');
    card.className = 'food-card';

    const image = document.createElement('div');
    image.className = 'food-card__image';
    image.style.backgroundImage = `linear-gradient(180deg, rgba(19, 17, 15, 0.04), rgba(19, 17, 15, 0.18)), url(${item.ImageUrl || 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=900&q=80'})`;

    const body = document.createElement('div');
    body.className = 'food-card__body';

    const meta = document.createElement('div');
    meta.className = 'food-card__meta';

    const title = document.createElement('h3');
    title.textContent = item.Name || 'Signature dish';

    const badge = document.createElement('span');
    badge.className = 'status-badge';
    badge.textContent = item.CategoryName || item.Category || 'Featured';
    meta.append(title, badge);

    const info = document.createElement('p');
    info.textContent = item.Description || 'Freshly made for your next order.';

    const footer = document.createElement('div');
    footer.className = 'food-card__meta';

    const price = document.createElement('span');
    price.className = 'food-card__price';
    price.textContent = formatMoney(item.Price || 0);

    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'button button--tomato button--small';
    button.textContent = 'Add to basket';
    button.addEventListener('click', () => addToCart(item));

    footer.append(price, button);
    body.append(meta, info, footer);
    card.append(image, body);
    foodGrid.append(card);
  });
}

function getCartRow(item) {
  const row = document.createElement('div');
  row.className = 'cart-item';

  const info = document.createElement('div');
  info.className = 'cart-item__info';

  const title = document.createElement('span');
  title.className = 'cart-item__title';
  title.textContent = item.name;

  const qty = document.createElement('span');
  qty.className = 'cart-item__qty';
  qty.textContent = `Qty: ${item.quantity}`;

  info.append(title, qty);

  const price = document.createElement('span');
  price.className = 'cart-item__price';
  price.textContent = formatMoney(item.price * item.quantity);

  const removeButton = document.createElement('button');
  removeButton.type = 'button';
  removeButton.className = 'button button--outline button--small';
  removeButton.textContent = 'Remove';
  removeButton.addEventListener('click', () => {
    state.cart = state.cart.filter((entry) => entry.foodItemId !== item.foodItemId);
    persistCart();
    renderCart();
  });

  row.append(info, price, removeButton);
  return row;
}

function renderCart() {
  if (!cartItems) return;
  cartItems.innerHTML = '';

  if (!state.cart.length) {
    const empty = document.createElement('p');
    empty.className = 'empty-copy';
    empty.textContent = 'Your basket is taking a little break.';
    cartItems.appendChild(empty);
    if (cartTotal) cartTotal.textContent = 'Rs. 0';
    if (cartCount) cartCount.textContent = '0';
    return;
  }

  let total = 0;
  state.cart.forEach((item) => {
    total += Number(item.price) * Number(item.quantity);
    cartItems.appendChild(getCartRow(item));
  });

  if (cartTotal) cartTotal.textContent = formatMoney(total);
  if (cartCount) cartCount.textContent = String(state.cart.reduce((sum, item) => sum + Number(item.quantity), 0));
}

function addToCart(item) {
  const foodItemId = getFoodId(item);
  const restaurantId = getRestaurantId(item);
  const existing = state.cart.find((entry) => Number(entry.foodItemId) === foodItemId);

  if (existing) existing.quantity += 1;
  else state.cart.push({ foodItemId, restaurantId, name: item.Name || 'Dish', price: Number(item.Price || 0), quantity: 1 });

  persistCart();
  renderCart();
  if (pageNotice) setNotice(pageNotice, 'Item added to basket.', 'success');
}

async function loadRestaurantOptions() {
  if (!restaurantFilter) return;
  const { restaurants = [] } = await api('/restaurants');
  state.restaurants = restaurants;
  const existingValue = restaurantFilter.value;
  restaurantFilter.innerHTML = '<option value="">All restaurants</option>';
  restaurants.forEach((restaurant) => {
    const option = document.createElement('option');
    option.value = String(restaurant.RestaurantID || restaurant.restaurantId || '');
    option.textContent = restaurant.Name || 'Kitchen';
    restaurantFilter.append(option);
  });
  restaurantFilter.value = existingValue || '';
}

async function loadFoods() {
  const params = new URLSearchParams();
  const search = (foodSearchInput?.value || '').trim();
  if (search) params.set('search', search);
  if (restaurantFilter && restaurantFilter.value) params.set('restaurantId', restaurantFilter.value);
  if (categoryFilter && categoryFilter.value) params.set('category', categoryFilter.value);
  if (maxPriceInput && maxPriceInput.value) params.set('maxPrice', maxPriceInput.value);

  const response = await api(`/food?${params.toString()}`);
  state.foods = response.items || [];
  renderFoods();
}

async function searchRestaurants(searchTerm) {
  if (!restaurantGrid) return;
  const params = new URLSearchParams();
  if (searchTerm) params.set('search', searchTerm);
  const { restaurants = [] } = await api(`/restaurants?${params.toString()}`);
  state.restaurants = restaurants;
  renderRestaurants(restaurants);
}

if (restaurantSearchForm && restaurantQuery) {
  restaurantSearchForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    await searchRestaurants(restaurantQuery.value.trim());
  });
}

if (restaurantFilter) {
  restaurantFilter.addEventListener('change', () => {
    if (foodGrid) loadFoods().catch((error) => setNotice(pageNotice, error.message, 'error'));
  });
}

if (categoryFilter) {
  categoryFilter.addEventListener('change', () => {
    if (foodGrid) loadFoods().catch((error) => setNotice(pageNotice, error.message, 'error'));
  });
}

if (maxPriceInput) {
  maxPriceInput.addEventListener('input', () => {
    if (foodGrid) loadFoods().catch((error) => setNotice(pageNotice, error.message, 'error'));
  });
}

if (foodSearchButton) {
  foodSearchButton.addEventListener('click', () => {
    loadFoods().catch((error) => setNotice(pageNotice, error.message, 'error'));
  });
}

if (foodSearchInput) {
  foodSearchInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
      event.preventDefault();
      loadFoods().catch((error) => setNotice(pageNotice, error.message, 'error'));
    }
  });
}

if (checkoutForm) {
  checkoutForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    if (!state.cart.length) {
      setNotice(checkoutNotice, 'Add items to basket first.', 'error');
      return;
    }

    const deliveryAddress = new FormData(checkoutForm).get('deliveryAddress')?.toString().trim();
    const payload = {
      restaurantId: state.cart[0].restaurantId,
      deliveryAddress,
      items: state.cart.map((item) => ({ foodItemId: item.foodItemId, quantity: item.quantity }))
    };

    try {
      await ensureLoggedIn();
      await api('/orders', {
        method: 'POST',
        headers: { 'Idempotency-Key': crypto.randomUUID() },
        body: JSON.stringify(payload)
      });
      state.cart = [];
      persistCart();
      renderCart();
      checkoutForm.reset();
      setNotice(checkoutNotice, 'Order placed successfully. Track it from Your orders.', 'success');
    } catch (error) {
      setNotice(checkoutNotice, error.message, 'error');
    }
  });
}

async function bootstrap() {
  renderCart();
  if (restaurantGrid) {
    await ensureLoggedIn().catch(() => null);
    try {
      await searchRestaurants(restaurantQuery?.value || '');
    } catch (error) {
      setNotice(pageNotice, error.message, 'error');
    }
  }

  if (foodGrid) {
    if (!restaurantFilter) {
      return;
    }
    try {
      await ensureLoggedIn().catch(() => null);
      await loadRestaurantOptions();
      await loadFoods();
    } catch (error) {
      setNotice(pageNotice, error.message, 'error');
    }
  }
}

bootstrap();
