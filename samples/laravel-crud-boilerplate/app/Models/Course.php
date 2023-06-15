<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Contracts\Pagination\Paginator;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Course extends Model
{
    // use soft delete instead of permanent delete
    use SoftDeletes;
    use HasFactory;

    protected $perPage = 2;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'courses';

    protected $fillable = ['students_id', 'course_id',];

    /**
     * The attributes that should be mutated to dates.
     *
     * @var array
     */
    protected $dates = ['deleted_at'];

    /**
     * The attributes that should be cast to native types.
     *
     * @var array
     */
    protected $casts = [

    ];

    /**
     * Load all for admin and paginate
     *
     * @return Paginator
     */
    public static function loadAll(): Paginator
    {
        return static::latest()
            ->paginate();
    }


    public function tutor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'tutor_id');
    }

    public function enrollments(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Enrollment::class, 'course_id');
    }


    public static function getAvailableCourses(string $language = null, string $type = null): ?\Illuminate\Contracts\Pagination\LengthAwarePaginator
    {
        $query = self::query()->where('deleted_at', null);

        if ($language) {
            $query->where('language', $language);
        }

        if ($type) {
            $query->where('type', $type);
        }

        $now = now();

        // DB 와 서버 모두 UTC
        return $query->where('available_from', '<=', $now)
            ->where('available_until', '>=', $now)->latest()->paginate();
    }

    public static function getAvailableOne(int $id = null)
    {
        $now = now();

        return self::query()->where('available_from', '<=', $now)
            ->where('available_until', '>=', $now)->find($id);

    }

}
