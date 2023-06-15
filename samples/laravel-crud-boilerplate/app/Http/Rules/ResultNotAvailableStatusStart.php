<?php

namespace App\Http\Rules;

use Illuminate\Contracts\Validation\Rule;
use App\Models\User;

class ResultNotAvailableStatusStart implements Rule
{
    public function passes($attribute, $value)
    {
        // 다른 필드의 값을 참조하여 유효성 검사를 수행합니다.
        $status = request()->input('status');

        if($status === 'Start' && $value != null){
            return false;
        }else{
            return true;
        }

    }

    public function message()
    {
        return 'The :attribute must be null when status is "Start".';
    }
}