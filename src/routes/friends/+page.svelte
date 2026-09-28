<script lang="ts">
	import { enhance } from '$app/forms';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	let copied: string | null = $state(null);

	async function copy(url: string) {
		try {
			await navigator.clipboard.writeText(url);
			copied = url;
		} catch {
			copied = null;
		}
	}
</script>

<svelte:head><title>Friends · Loaners</title></svelte:head>

<h1 class="text-xl font-bold">Friends</h1>

{#if data.friends.length}
	<ul class="mt-4 space-y-1">
		{#each data.friends as friend (friend.id)}
			<li class="card">{friend.display_name}</li>
		{/each}
	</ul>
{:else}
	<p class="mt-4 text-sm text-gray-500">No friends yet. Send someone an invite link.</p>
{/if}

<h2 class="section-title">Invite a friend</h2>
<p class="text-sm text-gray-600">
	Anyone with the link can become your friend. Each link works once and expires after 7 days.
</p>
<form method="POST" action="?/invite" class="mt-2" use:enhance>
	<button class="btn-primary">Create invite link</button>
</form>
{#if form?.error}<p class="mt-2 text-red-700" role="alert">{form.error}</p>{/if}

{#if data.invites.length}
	<ul class="mt-3 space-y-2">
		{#each data.invites as invite (invite.code)}
			<li class="card">
				<input
					class="input font-mono text-sm"
					readonly
					value={invite.url}
					aria-label="Invite link"
					onfocus={(e) => e.currentTarget.select()}
				/>
				<div class="mt-2 flex items-center justify-between gap-2">
					<span class="text-xs text-gray-500">
						Expires {new Date(invite.expires_at).toLocaleDateString()}
					</span>
					<button class="btn" onclick={() => copy(invite.url)}>
						{copied === invite.url ? 'Copied' : 'Copy link'}
					</button>
				</div>
			</li>
		{/each}
	</ul>
{/if}
