<script lang="ts">
	import { enhance } from '$app/forms';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	let addForm: HTMLFormElement | undefined = $state();
</script>

<svelte:head><title>My items · Loaners</title></svelte:head>

<h1 class="text-xl font-bold">My items</h1>

<form
	method="POST"
	action="?/add"
	class="card mt-4 space-y-2"
	bind:this={addForm}
	use:enhance={() =>
		async ({ result, update }) => {
			await update({ reset: result.type === 'success' });
			if (result.type === 'success')
				addForm?.querySelector<HTMLInputElement>('[name=name]')?.focus();
		}}
>
	<input
		class="input"
		name="name"
		placeholder="Item name"
		maxlength="100"
		required
		value={form && 'name' in form ? form.name : ''}
	/>
	<textarea
		class="input"
		name="note"
		placeholder="Note (optional): edition, condition, what's included"
		rows="2"
		maxlength="1000">{form && 'note' in form ? form.note : ''}</textarea
	>
	<button class="btn-primary">Add item</button>
	{#if form && 'added' in form}<p class="text-sm text-green-700">Added {form.added}.</p>{/if}
</form>

{#if form?.error}<p class="mt-3 text-red-700" role="alert">{form.error}</p>{/if}

<ul class="mt-4 space-y-2">
	{#each data.items as item (item.id)}
		<li class="card {item.archived_at ? 'opacity-60' : ''}">
			<div class="flex items-start justify-between gap-2">
				<div>
					<p class="font-medium">{item.name}</p>
					{#if item.note}<p class="text-sm text-gray-600">{item.note}</p>{/if}
					<p class="mt-1 text-xs text-gray-500">
						{#if item.archived_at}Archived{:else if item.visibility === 'private'}Private{:else}Visible
							to friends{/if}
						{#if item.borrower}· On loan to {item.borrower}{/if}
					</p>
				</div>
			</div>
			<div class="mt-2 flex flex-wrap gap-2">
				{#if !item.archived_at}
					<form method="POST" action="?/visibility" use:enhance>
						<input type="hidden" name="id" value={item.id} />
						<input
							type="hidden"
							name="visibility"
							value={item.visibility === 'private' ? 'friends' : 'private'}
						/>
						<button class="btn">
							{item.visibility === 'private' ? 'Show to friends' : 'Make private'}
						</button>
					</form>
					<form method="POST" action="?/archive" use:enhance>
						<input type="hidden" name="id" value={item.id} />
						<button class="btn">Archive</button>
					</form>
				{:else}
					<form method="POST" action="?/unarchive" use:enhance>
						<input type="hidden" name="id" value={item.id} />
						<button class="btn">Unarchive</button>
					</form>
				{/if}
			</div>
		</li>
	{:else}
		<p class="text-sm text-gray-500">No items yet. Add something you'd lend a friend.</p>
	{/each}
</ul>
