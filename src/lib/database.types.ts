export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
	graphql_public: {
		Tables: {
			[_ in never]: never;
		};
		Views: {
			[_ in never]: never;
		};
		Functions: {
			graphql: {
				Args: { extensions?: Json; operationName?: string; query?: string; variables?: Json };
				Returns: Json;
			};
		};
		Enums: {
			[_ in never]: never;
		};
		CompositeTypes: {
			[_ in never]: never;
		};
	};
	public: {
		Tables: {
			friendships: {
				Row: {
					created_at: string;
					user_a: string;
					user_b: string;
				};
				Insert: {
					created_at?: string;
					user_a: string;
					user_b: string;
				};
				Update: {
					created_at?: string;
					user_a?: string;
					user_b?: string;
				};
				Relationships: [
					{
						foreignKeyName: 'friendships_user_a_fkey';
						columns: ['user_a'];
						isOneToOne: false;
						referencedRelation: 'profiles';
						referencedColumns: ['id'];
					},
					{
						foreignKeyName: 'friendships_user_b_fkey';
						columns: ['user_b'];
						isOneToOne: false;
						referencedRelation: 'profiles';
						referencedColumns: ['id'];
					}
				];
			};
			invites: {
				Row: {
					code: string;
					created_at: string;
					expires_at: string;
					inviter_id: string;
					used_at: string | null;
					used_by: string | null;
				};
				Insert: {
					code: string;
					created_at?: string;
					expires_at?: string;
					inviter_id: string;
					used_at?: string | null;
					used_by?: string | null;
				};
				Update: {
					code?: string;
					created_at?: string;
					expires_at?: string;
					inviter_id?: string;
					used_at?: string | null;
					used_by?: string | null;
				};
				Relationships: [
					{
						foreignKeyName: 'invites_inviter_id_fkey';
						columns: ['inviter_id'];
						isOneToOne: false;
						referencedRelation: 'profiles';
						referencedColumns: ['id'];
					},
					{
						foreignKeyName: 'invites_used_by_fkey';
						columns: ['used_by'];
						isOneToOne: false;
						referencedRelation: 'profiles';
						referencedColumns: ['id'];
					}
				];
			};
			items: {
				Row: {
					archived_at: string | null;
					created_at: string;
					id: string;
					name: string;
					note: string | null;
					owner_id: string;
					visibility: string;
				};
				Insert: {
					archived_at?: string | null;
					created_at?: string;
					id?: string;
					name: string;
					note?: string | null;
					owner_id?: string;
					visibility?: string;
				};
				Update: {
					archived_at?: string | null;
					created_at?: string;
					id?: string;
					name?: string;
					note?: string | null;
					owner_id?: string;
					visibility?: string;
				};
				Relationships: [
					{
						foreignKeyName: 'items_owner_id_fkey';
						columns: ['owner_id'];
						isOneToOne: false;
						referencedRelation: 'profiles';
						referencedColumns: ['id'];
					}
				];
			};
			loans: {
				Row: {
					borrower_id: string;
					closed_at: string | null;
					id: string;
					item_id: string;
					message: string | null;
					owner_id: string;
					requested_at: string;
					returned_at: string | null;
					started_at: string | null;
					status: Database['public']['Enums']['loan_status'];
				};
				Insert: {
					borrower_id: string;
					closed_at?: string | null;
					id?: string;
					item_id: string;
					message?: string | null;
					owner_id: string;
					requested_at?: string;
					returned_at?: string | null;
					started_at?: string | null;
					status?: Database['public']['Enums']['loan_status'];
				};
				Update: {
					borrower_id?: string;
					closed_at?: string | null;
					id?: string;
					item_id?: string;
					message?: string | null;
					owner_id?: string;
					requested_at?: string;
					returned_at?: string | null;
					started_at?: string | null;
					status?: Database['public']['Enums']['loan_status'];
				};
				Relationships: [
					{
						foreignKeyName: 'loans_borrower_id_fkey';
						columns: ['borrower_id'];
						isOneToOne: false;
						referencedRelation: 'profiles';
						referencedColumns: ['id'];
					},
					{
						foreignKeyName: 'loans_item_id_fkey';
						columns: ['item_id'];
						isOneToOne: false;
						referencedRelation: 'items';
						referencedColumns: ['id'];
					},
					{
						foreignKeyName: 'loans_owner_id_fkey';
						columns: ['owner_id'];
						isOneToOne: false;
						referencedRelation: 'profiles';
						referencedColumns: ['id'];
					}
				];
			};
			profiles: {
				Row: {
					created_at: string;
					display_name: string | null;
					id: string;
				};
				Insert: {
					created_at?: string;
					display_name?: string | null;
					id: string;
				};
				Update: {
					created_at?: string;
					display_name?: string | null;
					id?: string;
				};
				Relationships: [];
			};
		};
		Views: {
			[_ in never]: never;
		};
		Functions: {
			accept_invite: { Args: { code: string }; Returns: undefined };
			cancel_request: { Args: { loan_id: string }; Returns: undefined };
			create_invite: { Args: Record<PropertyKey, never>; Returns: string };
			get_invite: {
				Args: { code: string };
				Returns: {
					inviter_name: string;
					reason: string;
					valid: boolean;
				}[];
			};
			mark_returned: { Args: { loan_id: string }; Returns: undefined };
			request_item: { Args: { item_id: string; message?: string }; Returns: string };
			respond_to_request: { Args: { accept: boolean; loan_id: string }; Returns: undefined };
			search_friend_items: {
				Args: { query?: string };
				Returns: {
					available: boolean;
					id: string;
					name: string;
					note: string;
					owner_id: string;
					owner_name: string;
					rank: number;
					requested_by_me: boolean;
				}[];
			};
		};
		Enums: {
			loan_status: 'requested' | 'declined' | 'cancelled' | 'active' | 'returned';
		};
		CompositeTypes: {
			[_ in never]: never;
		};
	};
};

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>;

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, 'public'>];

export type Tables<
	DefaultSchemaTableNameOrOptions extends
		| keyof (DefaultSchema['Tables'] & DefaultSchema['Views'])
		| { schema: keyof DatabaseWithoutInternals },
	TableName extends (DefaultSchemaTableNameOrOptions extends {
		schema: keyof DatabaseWithoutInternals;
	}
		? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'] &
				DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Views'])
		: never) = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
	? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'] &
			DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Views'])[TableName] extends {
			Row: infer R;
		}
		? R
		: never
	: DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema['Tables'] & DefaultSchema['Views'])
		? (DefaultSchema['Tables'] & DefaultSchema['Views'])[DefaultSchemaTableNameOrOptions] extends {
				Row: infer R;
			}
			? R
			: never
		: never;

export type TablesInsert<
	DefaultSchemaTableNameOrOptions extends
		keyof DefaultSchema['Tables'] | { schema: keyof DatabaseWithoutInternals },
	TableName extends (DefaultSchemaTableNameOrOptions extends {
		schema: keyof DatabaseWithoutInternals;
	}
		? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
		: never) = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
	? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
			Insert: infer I;
		}
		? I
		: never
	: DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
		? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
				Insert: infer I;
			}
			? I
			: never
		: never;

export type TablesUpdate<
	DefaultSchemaTableNameOrOptions extends
		keyof DefaultSchema['Tables'] | { schema: keyof DatabaseWithoutInternals },
	TableName extends (DefaultSchemaTableNameOrOptions extends {
		schema: keyof DatabaseWithoutInternals;
	}
		? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
		: never) = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
	? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
			Update: infer U;
		}
		? U
		: never
	: DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
		? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
				Update: infer U;
			}
			? U
			: never
		: never;

export type Enums<
	DefaultSchemaEnumNameOrOptions extends
		keyof DefaultSchema['Enums'] | { schema: keyof DatabaseWithoutInternals },
	EnumName extends (DefaultSchemaEnumNameOrOptions extends {
		schema: keyof DatabaseWithoutInternals;
	}
		? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums']
		: never) = never
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
	? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums'][EnumName]
	: DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema['Enums']
		? DefaultSchema['Enums'][DefaultSchemaEnumNameOrOptions]
		: never;

export type CompositeTypes<
	PublicCompositeTypeNameOrOptions extends
		keyof DefaultSchema['CompositeTypes'] | { schema: keyof DatabaseWithoutInternals },
	CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
		schema: keyof DatabaseWithoutInternals;
	}
		? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes']
		: never) = never
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
	? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes'][CompositeTypeName]
	: PublicCompositeTypeNameOrOptions extends keyof DefaultSchema['CompositeTypes']
		? DefaultSchema['CompositeTypes'][PublicCompositeTypeNameOrOptions]
		: never;

export const Constants = {
	graphql_public: {
		Enums: {}
	},
	public: {
		Enums: {
			loan_status: ['requested', 'declined', 'cancelled', 'active', 'returned']
		}
	}
} as const;
