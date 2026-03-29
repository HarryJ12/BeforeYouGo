<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Appointment extends Model
{
    use HasUuids;

    protected $fillable = [
        'id',
        'user_id',
        'doctor_name',
        'specialty',
        'date',
        'time',
        'reason',
        'location',
        'is_completed',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'is_completed' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function prep(): HasOne
    {
        return $this->hasOne(AppointmentPrep::class);
    }

    public function postVisitSummary(): HasOne
    {
        return $this->hasOne(PostVisitSummary::class);
    }
}
