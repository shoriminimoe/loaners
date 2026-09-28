import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '$lib/database.types';

declare global {
	namespace App {
		interface Locals {
			supabase: SupabaseClient<Database>;
			/** Verified from the session JWT; null when signed out. */
			user: { id: string; email: string | null } | null;
			/** The signed-in user's profile; null when signed out. */
			profile: { display_name: string | null } | null;
		}
	}
}

export {};
