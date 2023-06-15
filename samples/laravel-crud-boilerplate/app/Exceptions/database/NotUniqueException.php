<?php

namespace App\Exceptions\database;

use Exception;

class NotUniqueException extends \RuntimeException
{
    public function __construct($message = null)
    {
        $message = $message ?: 'Not unique data.';
        parent::__construct($message, 409);
    }

}