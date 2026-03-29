<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Provider extends Model
{
    use HasUuids;

    protected $fillable = [
        'id',
        'name',
        'specialty',
        'address',
        'phone',
        'latitude',
        'longitude',
        'rating',
        'accepts_insurance',
    ];

    protected function casts(): array
    {
        return [
            'accepts_insurance' => 'boolean',
            'rating' => 'float',
            'latitude' => 'float',
            'longitude' => 'float',
        ];
    }
}
