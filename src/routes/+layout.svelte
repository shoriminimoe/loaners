<script lang="ts">
	import './layout.css';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';

	let { data, children } = $props();

	const links = [
		{ href: '/', label: 'Home' },
		{ href: '/items', label: 'My items' },
		{ href: '/search', label: 'Search' },
		{ href: '/friends', label: 'Friends' }
	] as const;
</script>

<div class="min-h-screen bg-gray-50 text-gray-900">
	{#if data.displayName}
		<header class="border-b border-gray-200 bg-white">
			<div class="mx-auto flex max-w-xl items-center justify-between px-4 py-2">
				<span class="font-bold">Loaners</span>
				<form method="POST" action="/auth/signout" class="flex items-center gap-2 text-sm">
					<span class="text-gray-600">{data.displayName}</span>
					<button class="text-gray-600 underline">Sign out</button>
				</form>
			</div>
			<nav class="mx-auto flex max-w-xl gap-1 overflow-x-auto px-2 pb-2">
				{#each links as link (link.href)}
					<a
						href={resolve(link.href)}
						class="rounded px-3 py-1.5 text-sm whitespace-nowrap {page.url.pathname === link.href
							? 'bg-emerald-700 text-white'
							: 'text-gray-700 hover:bg-gray-100'}"
						aria-current={page.url.pathname === link.href ? 'page' : undefined}>{link.label}</a
					>
				{/each}
			</nav>
		</header>
	{/if}
	<main class="mx-auto max-w-xl px-4 py-4">
		{@render children()}
	</main>
</div>
