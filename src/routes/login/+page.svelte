<script lang="ts">
	import { enhance } from '$app/forms';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	let submitting = $state(false);
</script>

<svelte:head><title>Sign in · Loaners</title></svelte:head>

<h1 class="text-2xl font-bold">Loaners</h1>
<p class="mt-1 text-gray-600">Lend and borrow things with friends.</p>

{#if form?.sent}
	<p class="mt-6 rounded border border-green-300 bg-green-50 p-3" role="status">
		Check <strong>{form.email}</strong> for a sign-in link.
	</p>
{:else}
	<form
		method="POST"
		class="mt-6 space-y-3"
		use:enhance={() => {
			submitting = true;
			return async ({ update }) => {
				await update();
				submitting = false;
			};
		}}
	>
		<input type="hidden" name="next" value={data.next} />
		<label class="block">
			<span class="text-sm font-medium">Email</span>
			<input
				class="input mt-1"
				type="email"
				name="email"
				autocomplete="email"
				required
				value={form?.email ?? ''}
			/>
		</label>
		{#if data.linkError}
			<p class="text-red-700">That sign-in link is invalid or expired. Request a new one.</p>
		{/if}
		{#if form?.error}<p class="text-red-700">{form.error}</p>{/if}
		<button class="btn-primary w-full" disabled={submitting}>
			{submitting ? 'Sending…' : 'Email me a sign-in link'}
		</button>
	</form>
{/if}
