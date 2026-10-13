import { api, setNotice } from './api.js';

const loginForm = document.querySelector('#login-form');
const registerForm = document.querySelector('#register-form');
const notice = document.querySelector('[data-notice]');

loginForm?.addEventListener('submit', async (event) => {
	event.preventDefault();
	const submit = loginForm.querySelector('[type="submit"]');
	submit.disabled = true;
	try {
		await api('/auth/login', { method: 'POST', body: JSON.stringify(Object.fromEntries(new FormData(loginForm))) });
		location.href = '/menu.html';
	} catch (error) {
		setNotice(notice, error.message, 'error');
	} finally {
		submit.disabled = false;
	}
});

registerForm?.addEventListener('submit', async (event) => {
	event.preventDefault();
	const form = Object.fromEntries(new FormData(registerForm));
	if (form.password !== form.confirmPassword) return setNotice(notice, 'Passwords do not match.', 'error');
	delete form.confirmPassword;
	const submit = registerForm.querySelector('[type="submit"]');
	submit.disabled = true;
	try {
		await api('/auth/register', { method: 'POST', body: JSON.stringify(form) });
		location.href = '/menu.html';
	} catch (error) {
		setNotice(notice, error.message, 'error');
	} finally {
		submit.disabled = false;
	}
});

document.querySelectorAll('[data-logout]').forEach((button) => button.addEventListener('click', async () => {
	await api('/auth/logout', { method: 'POST' }).catch(() => null);
	location.href = '/';
}));
