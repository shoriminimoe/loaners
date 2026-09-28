import { fail } from '@sveltejs/kit';

/**
 * Turn a Supabase error into a form failure. RPC rule violations raise with
 * a readable message (see ADR 0003), so it is shown as-is.
 */
export function failWith(error: { message: string }, status = 400) {
	const message = error.message.charAt(0).toUpperCase() + error.message.slice(1);
	return fail(status, { error: message });
}
