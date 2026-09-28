<script lang="ts">
	import { enhance } from '$app/forms';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();

	type Loan = PageProps['data']['incoming'][number];

	const itemName = (l: Loan) => l.item?.name ?? 'Unavailable item';
	const date = (iso: string | null) => (iso ? new Date(iso).toLocaleDateString() : '');
</script>

<svelte:head><title>Home · Loaners</title></svelte:head>

{#if form?.error}<p class="mb-3 text-red-700" role="alert">{form.error}</p>{/if}

{#snippet empty(text: string)}
	<p class="text-sm text-gray-500">{text}</p>
{/snippet}

{#snippet loanAction(id: string, action: string, label: string, primary = false)}
	<form method="POST" action="?/{action}" use:enhance>
		<input type="hidden" name="loan_id" value={id} />
		<button class={primary ? 'btn-primary py-1.5 text-sm' : 'btn'}>{label}</button>
	</form>
{/snippet}

<h2 class="section-title mt-0">Requests for my items</h2>
{#each data.incoming as loan (loan.id)}
	<div class="card mb-2">
		<p><strong>{loan.borrower?.display_name}</strong> wants <strong>{itemName(loan)}</strong></p>
		{#if loan.message}<p class="mt-1 text-sm text-gray-600">“{loan.message}”</p>{/if}
		<div class="mt-2 flex gap-2">
			{@render loanAction(loan.id, 'accept', 'Accept', true)}
			{@render loanAction(loan.id, 'decline', 'Decline')}
		</div>
	</div>
{:else}
	{@render empty('No requests.')}
{/each}

<h2 class="section-title">My requests</h2>
{#each data.outgoing as loan (loan.id)}
	<div class="card mb-2 flex items-center justify-between gap-2">
		<p>
			<strong>{itemName(loan)}</strong> from {loan.owner?.display_name}
			<span class="block text-sm text-gray-500">Requested {date(loan.requested_at)}</span>
		</p>
		{@render loanAction(loan.id, 'cancel', 'Cancel')}
	</div>
{:else}
	{@render empty('You have no open requests.')}
{/each}

<h2 class="section-title">Lent out</h2>
{#each data.lent as loan (loan.id)}
	<div class="card mb-2 flex items-center justify-between gap-2">
		<p>
			<strong>{itemName(loan)}</strong> with {loan.borrower?.display_name}
			<span class="block text-sm text-gray-500">Since {date(loan.started_at)}</span>
		</p>
		{@render loanAction(loan.id, 'returned', 'Mark returned')}
	</div>
{:else}
	{@render empty('Nothing lent out.')}
{/each}

<h2 class="section-title">Borrowing</h2>
{#each data.borrowing as loan (loan.id)}
	<div class="card mb-2">
		<p>
			<strong>{itemName(loan)}</strong> from {loan.owner?.display_name}
			<span class="block text-sm text-gray-500">Since {date(loan.started_at)}</span>
		</p>
	</div>
{:else}
	{@render empty('You are not borrowing anything.')}
{/each}
