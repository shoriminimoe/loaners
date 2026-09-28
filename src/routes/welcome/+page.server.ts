import { fail, redirect } from '@sveltejs/kit';
import { safeNext } from '$lib/server/paths';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	const next = safeNext(url.searchParams.get('next'));
	if (locals.profile?.display_name) redirect(303, next);
	return { next };
};

export const actions: Actions = {
	default: async ({ request, locals }) => {
		const form = await request.formData();
		const displayName = String(form.get('display_name') ?? '').trim();
		const next = safeNext(String(form.get('next') ?? '/'));

		if (displayName.length < 1 || displayName.length > 50) {
			return fail(400, { displayName, error: 'Name must be 1 to 50 characters.' });
		}

		const { error } = await locals.supabase
			.from('profiles')
			.update({ display_name: displayName })
			.eq('id', locals.user!.id);
		if (error) return fail(400, { displayName, error: error.message });

		redirect(303, next);
	}
};
