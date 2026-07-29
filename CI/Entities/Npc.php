<?php

namespace App\Entities;
use CodeIgniter\Entity\Entity;

class Npc extends Entity {
    protected $attributes = [
        'id' => 0,
        'animesh' => '',
        'description' => '',
        'inserted_at' => null,
        'updated_at' => null,
        'deleted_at' => null,
    ];
    protected $casts = [
        'id' => 'integer',
        'animesh' => 'string',
        'messages' => 'string',
    ];
}
