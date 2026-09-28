/** Paths reachable without a session. */
const PUBLIC_PREFIXES = ['/login', '/auth/'];

export function isPublicPath(pathname: string): boolean {
	return PUBLIC_PREFIXES.some((p) => pathname === p || pathname.startsWith(p));
}

/** Only allow same-origin relative redirects. */
export function safeNext(next: string | null | undefined): string {
	if (!next || !next.startsWith('/') || next.startsWith('//') || next.startsWith('/\\')) return '/';
	return next;
}

/** Cookie holding where to go after the magic link is confirmed. */
export const NEXT_COOKIE = 'loaners_next';
