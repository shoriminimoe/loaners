import { fail } from '@sveltejs/kit';
import { failWith } from '$lib/server/errors';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const { data: items, error } = await locals.supabase
		.from('items')
		.select(
			`id, name, note, visibility, archived_at,
			 loans(status, borrower:profiles!loans_borrower_id_fkey(display_name))`
		)
		.eq('owner_id', locals.user!.id)
		.eq('loans.status', 'active')
		.order('archived_at', { ascending: true, nullsFirst: true })
		.order('name');
	if (error) throw error;

	return {
		items: items.map(({ loans, ...item }) => ({
			...item,
			borrower: loans[0]?.borrower?.display_name ?? null
		}))
	};
};

function itemId(form: FormData) {
	return String(form.get('id') ?? '');
}

export const actions: Actions = {
	add: async ({ request, locals }) => {
		const form = await request.formData();
		const name = String(form.get('name') ?? '').trim();
		const note = String(form.get('note') ?? '').trim();
		if (!name) return fail(400, { name, note, error: 'Name is required.' });

		const { error } = await locals.supabase.from('items').insert({ name, note: note || null });
		if (error) return fail(400, { name, note, error: error.message });
		return { added: name };
	},
	visibility: async ({ request, locals }) => {
		const form = await request.formData();
		const visibility = form.get('visibility') === 'private' ? 'private' : 'friends';
		const { error } = await locals.supabase
			.from('items')
			.update({ visibility })
			.eq('id', itemId(form));
		if (error) return failWith(error);
	},
	archive: async ({ request, locals }) => {
		const { error } = await locals.supabase
			.from('items')
			.update({ archived_at: new Date().toISOString() })
			.eq('id', itemId(await request.formData()));
		if (error) return failWith(error);
	},
	unarchive: async ({ request, locals }) => {
		const { error } = await locals.supabase
			.from('items')
			.update({ archived_at: null })
			.eq('id', itemId(await request.formData()));
		if (error) return failWith(error);
	}
};
