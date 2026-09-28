import { redirect } from '@sveltejs/kit';
import type { EmailOtpType } from '@supabase/supabase-js';
import { NEXT_COOKIE, safeNext } from '$lib/server/paths';
import type { RequestHandler } from './$types';

// Magic link target. The email template links here with a token hash, which
// works even when the link is opened in a different browser.
export const GET: RequestHandler = async ({ url, cookies, locals }) => {
	const tokenHash = url.searchParams.get('token_hash');
	const type = url.searchParams.get('type') as EmailOtpType | null;
	const next = safeNext(cookies.get(NEXT_COOKIE));
	cookies.delete(NEXT_COOKIE, { path: '/' });

	if (tokenHash && type) {
		const { error } = await locals.supabase.auth.verifyOtp({ token_hash: tokenHash, type });
		if (!error) redirect(303, next);
	}

	redirect(303, '/login?error=link');
};
