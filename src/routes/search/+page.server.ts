import { failWith } from '$lib/server/errors';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	const q = url.searchParams.get('q')?.trim() ?? '';
	const { data: results, error } = await locals.supabase.rpc('search_friend_items', { query: q });
	if (error) throw error;
	return { q, results };
};

export const actions: Actions = {
	request: async ({ request, locals }) => {
		const form = await request.formData();
		const { error } = await locals.supabase.rpc('request_item', {
			item_id: String(form.get('item_id') ?? ''),
			message: String(form.get('message') ?? '')
		});
		if (error) return failWith(error);
		return { requested: String(form.get('item_name') ?? 'item') };
	}
};
