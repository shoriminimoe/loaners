import { failWith } from '$lib/server/errors';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	const me = locals.user!.id;

	// RLS returns only the caller's own profile and their friends'.
	const [friends, invites] = await Promise.all([
		locals.supabase.from('profiles').select('id, display_name').neq('id', me).order('display_name'),
		locals.supabase
			.from('invites')
			.select('code, expires_at')
			.eq('inviter_id', me)
			.is('used_at', null)
			.gt('expires_at', new Date().toISOString())
			.order('created_at', { ascending: false })
	]);
	if (friends.error) throw friends.error;
	if (invites.error) throw invites.error;

	return {
		friends: friends.data,
		invites: invites.data.map((i) => ({ ...i, url: `${url.origin}/invite/${i.code}` }))
	};
};

export const actions: Actions = {
	invite: async ({ locals }) => {
		const { error } = await locals.supabase.rpc('create_invite');
		if (error) return failWith(error);
	}
};
