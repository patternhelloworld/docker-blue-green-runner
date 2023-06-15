<?php

namespace App\Http\Rules;

use App\Models\Course;
use Illuminate\Contracts\Validation\Rule;
use App\Models\User;

class CourseValidity implements Rule
{
    public function passes($attribute, $value)
    {
        return (bool)Course::getAvailableOne($value);
    }

    public function message()
    {
        return 'The course_id (:attribute) does NOT exist.';
    }
}