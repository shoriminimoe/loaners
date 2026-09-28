import { redirect } from '@sveltejs/kit';
import { failWith } from '$lib/server/errors';
import type { Actions, PageServerLoad } from './$types';

// Signed-out visitors are sent through /login by the auth guard in hooks.
export const load: PageServerLoad = async ({ locals, params }) => {
	const { data, error } = await locals.supabase.rpc('get_invite', { code: params.code });
	if (error) throw error;
	return { invite: data[0] ?? null };
};

export const actions: Actions = {
	default: async ({ locals, params }) => {
		const { error } = await locals.supabase.rpc('accept_invite', { code: params.code });
		if (error) return failWith(error);
		redirect(303, '/friends');
	}
};
