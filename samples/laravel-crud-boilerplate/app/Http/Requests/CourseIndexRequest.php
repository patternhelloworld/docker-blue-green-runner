<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CourseIndexRequest extends FormRequest
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
            'language'  => ['nullable', 'in:en,cn'],
            'type' => ['nullable', 'in:Voice,Video,Chat']
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
            'language.in' => 'The selected language is invalid.',
            'type.in' => 'The selected type is invalid.',
        ];
    }

}
