<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AppointmentPrep extends Model
{
    protected $fillable = [
        'appointment_id',
        'what_to_mention',
        'questions_to_ask',
        'summary',
    ];

    protected function casts(): array
    {
        return [
            'what_to_mention' => 'array',
            'questions_to_ask' => 'array',
        ];
    }

    public function appointment(): BelongsTo
    {
        return $this->belongsTo(Appointment::class);
    }
}
