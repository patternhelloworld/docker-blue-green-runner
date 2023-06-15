<?php

namespace App\Exceptions\database;

use Exception;

class RowNotFoundException extends \RuntimeException
{
    public function __construct($message = null)
    {
        $message = $message ?: 'Row NOT found on DB.';
        parent::__construct($message, 404);
    }

}