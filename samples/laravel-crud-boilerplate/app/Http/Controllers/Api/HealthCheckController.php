<?php

namespace App\Http\Controllers\Api;


use App\Http\Controllers\Controller;

class HealthCheckController extends Controller
{
    public function index()
    {
        $component = array();

        $downCount = 0;
        foreach (array("database") as $name) {
            $componentStatus = app('pragmarx.health')->checkResource($name)->isHealthy();

            if($componentStatus){
                $detailArr['status'] =   'UP' ;
            }else{
                $downCount++;
                $detailArr['status'] =   'DOWN';
            }
            $component[$name] = $detailArr;
        }

        $finalUpDown = array();
        if($downCount > 0){
            $finalUpDown['status'] = 'DOWN' ;
        }else{
            $finalUpDown['status'] = 'UP' ;
        }
        $finalUpDown['component'] = $component;

        return response($finalUpDown, 200);
    }

}
