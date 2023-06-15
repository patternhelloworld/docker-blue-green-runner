<?php

namespace App\Http\DTOs;

use App\Http\Requests\CourseIndexRequest;
use Spatie\DataTransferObject\DataTransferObject;

class CourseIndexDTO extends DataTransferObject
{
    public $language;
    public $type;

    public static function fromRequest(CourseIndexRequest $request): CourseIndexDTO
    {
        return new static([
            'language' => $request->input('language'),
            'type' => $request->input('type'),
        ]);
    }

    /**
     * @return mixed
     */
    public function getLanguage()
    {
        return $this->language;
    }

    /**
     * @return mixed
     */
    public function getType()
    {
        return $this->type;
    }

}