<script lang="ts">
	import { enhance } from '$app/forms';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
</script>

<svelte:head><title>Welcome · Loaners</title></svelte:head>

<h1 class="text-2xl font-bold">Welcome to Loaners</h1>
<p class="mt-1 text-gray-600">Pick the name your friends will see.</p>

<form method="POST" class="mt-6 space-y-3" use:enhance>
	<input type="hidden" name="next" value={data.next} />
	<label class="block">
		<span class="text-sm font-medium">Display name</span>
		<input
			class="input mt-1"
			name="display_name"
			maxlength="50"
			required
			autocomplete="nickname"
			value={form?.displayName ?? ''}
		/>
	</label>
	{#if form?.error}<p class="text-red-700">{form.error}</p>{/if}
	<button class="btn-primary w-full">Continue</button>
</form>
