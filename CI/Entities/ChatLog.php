<?php

namespace App\Entities;
use CodeIgniter\Entity\Entity;

class ChatLog extends Entity {
    protected $attributes = [
        'id' => 0,
        'avatar' => 0,
        'animesh' => 0,
        'interaction_id' => '',
        'inserted_at' => null,
        'updated_at' => null,
        'deleted_at' => null,
    ];
    protected $casts = [
        'id' => 'integer',
        'avatar' => 'integer',
        'animesh' => 'integer',
        'interaction_id' => 'string',
    ];
}
