<?php

use Illuminate\Support\Facades\Route;

Route::group(['middleware' => 'auth:api'], function() {

    Route::get('/', 'CourseController@index')->name('courses.index');
    Route::group(['middleware' => 'auth.admin'], function() {
        Route::delete('/{id}', 'CourseController@delete')->name('courses.delete');
        Route::patch('/{id}', 'CourseController@restore')->name('courses.restore');
    });
});
