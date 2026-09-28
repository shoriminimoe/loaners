import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = async ({ locals }) => {
	return { displayName: locals.profile?.display_name ?? null };
};
