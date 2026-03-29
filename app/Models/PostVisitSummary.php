<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PostVisitSummary extends Model
{
    protected $fillable = [
        'appointment_id',
        'user_id',
        'raw_text',
        'what_doctor_found',
        'what_this_means',
        'what_to_do',
    ];

    public function appointment(): BelongsTo
    {
        return $this->belongsTo(Appointment::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
