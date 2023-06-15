<?php

namespace App\Http\Requests;

use App\Http\Rules\CourseValidity;
use App\Http\Rules\RecordingNotAvailableStatusStart;
use App\Http\Rules\ResultNotAvailableStatusStart;
use App\Http\Rules\StudentUserId;
use App\Http\Rules\TutorUserId;
use Illuminate\Foundation\Http\FormRequest;

class LessonStoreRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     *
     * @return bool
     */
    public function authorize()
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array
     */
    public function rules()
    {
        return [
            'student_id'  => ['required', new StudentUserId],
            'course_id'  => ['required',  new CourseValidity],
            'status' => ['required', 'in:Start,End'],
            'result' => ['nullable', new ResultNotAvailableStatusStart],
            'recording' => ['nullable', new RecordingNotAvailableStatusStart]
        ];
    }

    /**
     * Get the error messages for the defined validation rules.
     *
     * @return array
     */
    public function messages()
    {
        return [
            'status.required' => 'The status field is required.',
            'status.in' => 'The selected status is invalid. Valid values are Start or End.',
        ];
    }
}
