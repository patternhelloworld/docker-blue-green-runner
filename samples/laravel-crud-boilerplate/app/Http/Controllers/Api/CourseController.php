<?php

namespace App\Http\Controllers\Api;

use App\Http\DTOs\CourseIndexDTO;
use App\Http\Requests\CourseIndexRequest;
use App\Models\Course;
use App\Http\Controllers\Controller;
use App\Models\Enrollment;
use App\Models\Lesson;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class CourseController extends Controller
{
    /**
     * Display a paginated listing of courses
     *
     * @param CourseIndexRequest $request
     * @return LengthAwarePaginator
     */
    public function index(CourseIndexRequest $request): LengthAwarePaginator
    {
        $courseIndexDTO = CourseIndexDTO::fromRequest($request);
        return Course::getAvailableCourses($courseIndexDTO->getLanguage(), $courseIndexDTO->getType());
    }


    /**
     *
     * 관리자가 Course 를 비활성화 할 경우. (Middleware 에서 현재 사용자가 Admin 으로  되어야 함.)
     * @param $id
     * @return \Illuminate\Contracts\Foundation\Application|\Illuminate\Contracts\Routing\ResponseFactory|\Illuminate\Http\Response
     * @throws \Throwable
     */
    public function delete($id)
    {
        DB::beginTransaction();

        try {

            // These are all "Soft Delete".
            Course::query()->where('id', $id)->delete();
            Enrollment::query()->where('course_id', $id)->delete();
            Lesson::query()->whereIn('enrollment_id',
                Enrollment::withTrashed()->where('course_id', $id)->get()->pluck('id')->toArray())->delete();

            DB::commit();

        }
        catch (\Throwable $e){
            DB::rollBack();
            throw $e;
        }
        return response(null, 200);
    }

    /**
     *
     * 관리자가 Course 를 활성화 할 경우. (Middleware 에서 현재 사용자가 Admin 으로 되어야 함.)
     * @param $id
     * @return \Illuminate\Contracts\Foundation\Application|\Illuminate\Contracts\Routing\ResponseFactory|\Illuminate\Http\Response
     * @throws \Throwable
     */
    public function restore($id)
    {
        DB::beginTransaction();

        try {

            Course::withTrashed()->where('id', $id)->restore();
            Enrollment::withTrashed()->where('course_id', $id)->restore();
            Lesson::withTrashed()->whereIn('enrollment_id',
                Enrollment::withTrashed()->where('course_id', $id)->get()->pluck('id')->toArray())->restore();

            DB::commit();

        }catch (\Throwable $e){
            DB::rollBack();
            throw $e;
        }
        return response([], 200);
    }
}
