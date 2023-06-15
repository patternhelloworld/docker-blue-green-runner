<?php

namespace App\Http\Rules;

use Illuminate\Contracts\Validation\Rule;
use App\Models\User;

class TutorUserId implements Rule
{
    public function passes($attribute, $value)
    {
        return User::find($value)->type === 'Tutor';
    }

    public function message()
    {
        return 'The :attribute must be Tutor.';
    }
}