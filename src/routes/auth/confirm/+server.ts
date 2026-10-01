import { redirect } from '@sveltejs/kit';
import type { EmailOtpType } from '@supabase/supabase-js';
import { NEXT_COOKIE, safeNext } from '$lib/server/paths';
import type { RequestHandler } from './$types';

// Magic link target. Supabase's default email links go through its /verify
// endpoint, which redirects here with a PKCE `code`; exchanging it needs the
// verifier cookie set when the link was requested, so it must be opened in
// the same browser. A custom template can link here with a `token_hash`
// instead, which works in any browser.
export const GET: RequestHandler = async ({ url, cookies, locals }) => {
	const code = url.searchParams.get('code');
	const tokenHash = url.searchParams.get('token_hash');
	const type = url.searchParams.get('type') as EmailOtpType | null;
	const next = safeNext(cookies.get(NEXT_COOKIE));
	cookies.delete(NEXT_COOKIE, { path: '/' });

	if (code) {
		const { error } = await locals.supabase.auth.exchangeCodeForSession(code);
		if (!error) redirect(303, next);
	} else if (tokenHash && type) {
		const { error } = await locals.supabase.auth.verifyOtp({ token_hash: tokenHash, type });
		if (!error) redirect(303, next);
	}

	redirect(303, '/login?error=link');
};
