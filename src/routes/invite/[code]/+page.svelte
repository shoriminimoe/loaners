<script lang="ts">
	import { enhance } from '$app/forms';
	import { resolve } from '$app/paths';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
</script>

<svelte:head><title>Invite · Loaners</title></svelte:head>

{#if !data.invite}
	<h1 class="text-xl font-bold">Invite not found</h1>
	<p class="mt-2 text-gray-600">Check the link, or ask your friend for a new one.</p>
{:else if !data.invite.valid}
	<h1 class="text-xl font-bold">Invite from {data.invite.inviter_name}</h1>
	<p class="mt-2 text-gray-600">
		This invite can't be used: {data.invite.reason}.
	</p>
	<a class="btn mt-4" href={resolve('/friends')}>Go to friends</a>
{:else}
	<h1 class="text-xl font-bold">{data.invite.inviter_name} invited you</h1>
	<p class="mt-2 text-gray-600">Accept to become friends and see each other's items on Loaners.</p>
	<form method="POST" class="mt-4" use:enhance>
		<button class="btn-primary">Accept invite</button>
	</form>
	{#if form?.error}<p class="mt-2 text-red-700" role="alert">{form.error}</p>{/if}
{/if}
