import { failWith } from '$lib/server/errors';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const me = locals.user!.id;

	// RLS limits loans to ones where the caller is owner or borrower.
	const { data: loans, error } = await locals.supabase
		.from('loans')
		.select(
			`id, status, message, requested_at, started_at, owner_id, borrower_id,
			 item:items(name),
			 owner:profiles!loans_owner_id_fkey(display_name),
			 borrower:profiles!loans_borrower_id_fkey(display_name)`
		)
		.in('status', ['requested', 'active'])
		.order('requested_at', { ascending: false });
	if (error) throw error;

	return {
		incoming: loans.filter((l) => l.status === 'requested' && l.owner_id === me),
		outgoing: loans.filter((l) => l.status === 'requested' && l.borrower_id === me),
		lent: loans.filter((l) => l.status === 'active' && l.owner_id === me),
		borrowing: loans.filter((l) => l.status === 'active' && l.borrower_id === me)
	};
};

function loanId(form: FormData) {
	return String(form.get('loan_id') ?? '');
}

export const actions: Actions = {
	accept: async ({ request, locals }) => {
		const loan_id = loanId(await request.formData());
		const { error } = await locals.supabase.rpc('respond_to_request', { loan_id, accept: true });
		if (error) return failWith(error);
	},
	decline: async ({ request, locals }) => {
		const loan_id = loanId(await request.formData());
		const { error } = await locals.supabase.rpc('respond_to_request', { loan_id, accept: false });
		if (error) return failWith(error);
	},
	cancel: async ({ request, locals }) => {
		const loan_id = loanId(await request.formData());
		const { error } = await locals.supabase.rpc('cancel_request', { loan_id });
		if (error) return failWith(error);
	},
	returned: async ({ request, locals }) => {
		const loan_id = loanId(await request.formData());
		const { error } = await locals.supabase.rpc('mark_returned', { loan_id });
		if (error) return failWith(error);
	}
};
