<?php

namespace App\Exceptions\database;

use Exception;

class ForeignKeyException extends \RuntimeException
{
    public function __construct($message = null)
    {
        $message = $message ?: 'Foreign key constraint violation.';
        parent::__construct($message, 422);
    }

}