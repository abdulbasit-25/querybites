import { api } from './api.js';

const form = document.querySelector('#chat-form');
const feed = document.querySelector('#chat-feed');
const input = document.querySelector('#chat-message');

function addMessage(text, sender) {
	const row = document.createElement('div');
	row.className = `chat-message chat-message--${sender}`;
	const paragraph = document.createElement('p');
	paragraph.textContent = text;
	row.append(paragraph);
	feed.append(row);
	feed.scrollTop = feed.scrollHeight;
}

form?.addEventListener('submit', async (event) => {
	event.preventDefault();
	const message = input.value.trim();
	if (!message) return;
	input.value = '';
	addMessage(message, 'user');
	const submit = form.querySelector('[type="submit"]');
	submit.disabled = true;
	try {
		const result = await api('/chat', { method: 'POST', body: JSON.stringify({ message }) });
		addMessage(result.reply, 'bot');
	} catch (error) {
		addMessage(error.message, 'bot');
	} finally {
		submit.disabled = false;
		input.focus();
	}
});
