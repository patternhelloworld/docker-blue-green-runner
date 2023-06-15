<?php


namespace Database\Factories;


use App\Models\Enrollment;
use App\Models\User;
use App\Models\Article;
use Illuminate\Support\Str;
use Illuminate\Support\Carbon;
use Illuminate\Database\Eloquent\Factories\Factory;

class EnrollmentFactory extends Factory
{
    protected $model = Enrollment::class;

    public function definition()
    {
        $title = $this->faker->sentence;

        return [
            'student_id' => User::factory(),
            'title' => $title,
            'slug' => Str::slug($title),
            'description' => $this->faker->sentence(15),
            'content' => implode(' ', $this->faker->paragraphs(2)),
            'published' => true,
            'published_at' => Carbon::now(),
        ];
    }
}
