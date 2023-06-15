<?php

namespace App\Http\Rules;

use Illuminate\Contracts\Validation\Rule;
use App\Models\User;

class StudentUserId implements Rule
{
    public function passes($attribute, $value)
    {
        return User::find($value)->type === 'Student';
    }

    public function message()
    {
        return 'The :attribute must be Student.';
    }
}