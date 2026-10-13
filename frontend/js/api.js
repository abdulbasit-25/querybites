const API_BASE = '/api';

export async function api(path, options = {}) {
	const response = await fetch(`${API_BASE}${path}`, {
		credentials: 'include',
		headers: { 'Content-Type': 'application/json', ...options.headers },
		...options
	});
	if (response.status === 204) return null;
	const payload = await response.json().catch(() => ({}));
	if (!response.ok) throw new Error(payload.error || 'The request could not be completed.');
	return payload;
}

export function setNotice(element, message, kind = 'info') {
	if (!element) return;
	element.textContent = message;
	element.dataset.kind = kind;
	element.hidden = !message;
}

export function formatMoney(value) {
	return `Rs. ${Number(value).toLocaleString('en-PK', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`;
}
