import { NextRequest, NextResponse } from 'next/server';

// Temporary minimal middleware - will add auth guards in Phase 2
export function middleware(request: NextRequest) {
  // Locale handling via cookie (set by UI toggle)
  const locale = request.cookies.get('NEXT_LOCALE')?.value || 'en-US';
  
  // TODO Phase 2: Add Supabase session check
  // TODO Phase 2: Redirect to /login if no session
  // TODO Phase 2: Check profiles.onboarded, redirect to /onboarding if false
  // TODO Phase 2: Check profiles.status, return 403 if banned
  // TODO Phase 8: /admin route protection (role=admin)

  const response = NextResponse.next();
  
  // Ensure locale cookie persists
  if (!request.cookies.get('NEXT_LOCALE')) {
    response.cookies.set('NEXT_LOCALE', locale, { 
      maxAge: 365 * 24 * 60 * 60,
      path: '/',
      sameSite: 'lax'
    });
  }

  return response;
}

export const config = {
  matcher: [
    '/((?!api|_next/static|_next/image|favicon.ico|.*\\..*|manifest.json).*)',
  ],
};
