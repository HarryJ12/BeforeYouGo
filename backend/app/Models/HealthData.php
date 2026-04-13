<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HealthData extends Model
{
    protected $fillable = ['user_id', 'metric_type', 'value', 'unit', 'recorded_at'];

    protected function casts(): array
    {
        return [
            'recorded_at' => 'datetime',
            'value' => 'float',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
