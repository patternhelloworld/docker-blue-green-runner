<?php

namespace App\Http\Controllers\Api;


use App\Exceptions\database\ForeignKeyException;
use App\Exceptions\database\NotUniqueException;
use App\Exceptions\database\RowNotFoundException;
use App\Http\Controllers\Controller;
use App\Http\DTOs\LessonStoreDTO;
use App\Http\Requests\LessonStoreRequest;
use App\Models\Enrollment;
use App\Models\Lesson;

class LessonController extends Controller
{

    /**
     *
         * Store a lesson & End it.
         * [CourseController 의 delete 참조] 다른 곳의 USER 또는 COURSE 를 비활성화 하는 코드에서 Transaction 을 사용하여
         * Enrollment, Lesson 테이블 까지 deleted_at 을 표시하는 일관성을 보장해야 한다.

     * @param LessonStoreRequest $request
     * @return \Illuminate\Http\JsonResponse
     * @throws ForeignKeyException
     * @throws \Throwable
     */
    public function store(LessonStoreRequest $request)
    {
        $lessonStoreDTO = LessonStoreDTO::fromRequest($request);

        $enrollment = Enrollment::getOne($lessonStoreDTO->getCourseId(), $lessonStoreDTO->getStudentId());
        if(!$enrollment){
            // 관리자가 CourseController 에서 Soft Delete 를 했다면 여기로 옴.
            throw new RowNotFoundException("The enrollment is NOT available. (Course ID : " . $lessonStoreDTO->getCourseId() . ", Student ID : " . $lessonStoreDTO->getStudentId() . ")");
        }

        try {

            $lesson = Lesson::query()->where('enrollment_id', $enrollment->id)
                ->where('status', $lessonStoreDTO->getStatus())->first();
            if($lesson){
                throw new NotUniqueException("Enrollment ID : " . $enrollment->id . " has already been " . strtolower($lessonStoreDTO->getStatus()) .  "ed.");
            }

            $lesson = Lesson::query()->create([
                'enrollment_id' => $enrollment->id,
                'status' => $lessonStoreDTO->getStatus(),
                'result' => $lessonStoreDTO->getResult(),
                'recording' => $lessonStoreDTO->getRecording()
            ]);
        }catch (\Throwable $e){

            $matches = array();

            // 상기 Lesson::query()->where 문이 진행되는 동안, 다른 Transaction 에서 이미 등록한 경우.
            // SQLSTATE[23000]: Integrity constraint violation: 1062 Duplicate entry '3-Start' for key
            // 에서 3은 id / 하이픈 뒤는 Status
            if($e->getCode() == "23000" && preg_match('/Duplicate entry \'[0-9]+?-(Start|End)\'/', $e->getMessage(), $matches)){
                throw new NotUniqueException("Enrollment ID : " . $enrollment->id . " has already been " . strtolower($matches[1]) .  "ed.");
            }else{
                throw $e;
            }

        }

        // 이메일 발송의 경우 laravel-queue 를 사용하여 구현. (Dockerfile 에서 supervisor 를 설치하여 이를 관리 (동시에 몇 개를 실행해야 할 지, 실패 시 재시도 횟수 등) 해야 함.)

        return response()->json($lesson, 201);
    }

}
