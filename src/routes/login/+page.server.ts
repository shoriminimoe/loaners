import { fail, redirect } from '@sveltejs/kit';
import { NEXT_COOKIE, safeNext } from '$lib/server/paths';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	if (locals.user) redirect(303, safeNext(url.searchParams.get('next')));
	return {
		next: safeNext(url.searchParams.get('next')),
		linkError: url.searchParams.get('error') === 'link'
	};
};

export const actions: Actions = {
	default: async ({ request, locals, url, cookies }) => {
		const form = await request.formData();
		const email = String(form.get('email') ?? '').trim();
		const next = safeNext(String(form.get('next') ?? '/'));

		if (!email.includes('@')) return fail(400, { email, error: 'Enter a valid email address.' });

		const { error } = await locals.supabase.auth.signInWithOtp({
			email,
			options: { emailRedirectTo: `${url.origin}/auth/confirm` }
		});
		if (error) return fail(400, { email, error: error.message });

		cookies.set(NEXT_COOKIE, next, {
			path: '/',
			httpOnly: true,
			sameSite: 'lax',
			maxAge: 60 * 60
		});
		return { email, sent: true };
	}
};
