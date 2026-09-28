<script lang="ts">
	import { enhance } from '$app/forms';
	import { resolve } from '$app/paths';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	let open: string | null = $state(null);
</script>

<svelte:head><title>Search · Loaners</title></svelte:head>

<h1 class="text-xl font-bold">Search friends' items</h1>

<form method="GET" class="mt-4 flex gap-2" data-sveltekit-keepfocus>
	<input class="input" type="search" name="q" value={data.q} placeholder="tent, zelda, dune…" />
	<button class="btn-primary">Search</button>
</form>

{#if form?.error}<p class="mt-3 text-red-700" role="alert">{form.error}</p>{/if}
{#if form && 'requested' in form}
	<p class="mt-3 text-green-700" role="status">
		Requested {form.requested}. It's on your <a class="underline" href={resolve('/')}>home page</a>.
	</p>
{/if}

<ul class="mt-4 space-y-2">
	{#each data.results as item (item.id)}
		<li class="card">
			<div class="flex items-start justify-between gap-2">
				<div>
					<p class="font-medium">{item.name}</p>
					{#if item.note}<p class="text-sm text-gray-600">{item.note}</p>{/if}
					<p class="mt-1 text-xs text-gray-500">{item.owner_name}</p>
				</div>
				{#if !item.available}
					<span class="text-sm whitespace-nowrap text-gray-500">On loan</span>
				{:else if item.requested_by_me}
					<span class="text-sm whitespace-nowrap text-gray-500">Requested</span>
				{:else if open !== item.id}
					<button class="btn" onclick={() => (open = item.id)}>Request</button>
				{/if}
			</div>
			{#if open === item.id && item.available && !item.requested_by_me}
				<form
					method="POST"
					action="?/request"
					class="mt-2 space-y-2"
					use:enhance={() =>
						async ({ update }) => {
							await update();
							open = null;
						}}
				>
					<input type="hidden" name="item_id" value={item.id} />
					<input type="hidden" name="item_name" value={item.name} />
					<input
						class="input"
						name="message"
						maxlength="500"
						placeholder="Message to {item.owner_name} (optional)"
					/>
					<div class="flex gap-2">
						<button class="btn-primary py-1.5 text-sm">Send request</button>
						<button type="button" class="btn" onclick={() => (open = null)}>Cancel</button>
					</div>
				</form>
			{/if}
		</li>
	{:else}
		<p class="text-sm text-gray-500">
			{#if data.q}No matches for “{data.q}”.{:else}Your friends haven't shared any items yet.
				<a class="underline" href={resolve('/friends')}>Invite a friend</a>.{/if}
		</p>
	{/each}
</ul>
