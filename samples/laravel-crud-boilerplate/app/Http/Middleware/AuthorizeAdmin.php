<?php

namespace App\Http\Middleware;

use Illuminate\Support\Facades\Auth;

class AuthorizeAdmin
{
    public function handle($request, \Closure $next)
    {
        $user = Auth::user();

        if ($user && $user->is_admin) {
            return $next($request);
        }

        abort(403, 'Unauthorized');
    }
}