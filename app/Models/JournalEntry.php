<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class JournalEntry extends Model
{
    use HasUuids;

    protected $fillable = [
        'id',
        'user_id',
        'date',
        'mood',
        'symptoms',
        'activities',
        'notes',
        'ai_summary',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'datetime',
            'symptoms' => 'array',
            'activities' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
