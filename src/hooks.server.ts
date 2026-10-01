import { createServerClient } from '@supabase/ssr';
import { redirect, type Handle } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';
import { env } from '$env/dynamic/public';
import type { Database } from '$lib/database.types';
import { isPublicPath } from '$lib/server/paths';

const supabase: Handle = async ({ event, resolve }) => {
	event.locals.supabase = createServerClient<Database>(
		env.PUBLIC_SUPABASE_URL,
		env.PUBLIC_SUPABASE_PUBLISHABLE_KEY,
		{
			cookies: {
				getAll: () => event.cookies.getAll(),
				setAll: (cookiesToSet) => {
					for (const { name, value, options } of cookiesToSet) {
						event.cookies.set(name, value, { ...options, path: '/' });
					}
				}
			}
		}
	);

	// getClaims verifies the JWT rather than trusting the cookie contents.
	const { data } = await event.locals.supabase.auth.getClaims();
	const claims = data?.claims;
	event.locals.user = claims ? { id: claims.sub, email: claims.email ?? null } : null;
	event.locals.profile = null;

	return resolve(event, {
		filterSerializedResponseHeaders: (name) =>
			name === 'content-range' || name === 'x-supabase-api-version'
	});
};

const guard: Handle = async ({ event, resolve }) => {
	const { pathname, search, searchParams } = event.url;

	// If the email link fell back to the Site URL, forward it to the confirm route.
	const fromEmail =
		searchParams.has('token_hash') || (pathname === '/' && searchParams.has('code'));
	if (fromEmail && pathname !== '/auth/confirm') {
		redirect(303, `/auth/confirm${search}`);
	}

	if (isPublicPath(pathname)) return resolve(event);

	const { user, supabase } = event.locals;
	if (!user) {
		redirect(303, `/login?next=${encodeURIComponent(pathname + search)}`);
	}

	const { data: profile } = await supabase
		.from('profiles')
		.select('display_name')
		.eq('id', user.id)
		.single();
	event.locals.profile = profile;

	if (!profile?.display_name && pathname !== '/welcome') {
		redirect(303, `/welcome?next=${encodeURIComponent(pathname + search)}`);
	}

	return resolve(event);
};

export const handle = sequence(supabase, guard);
