<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Medication extends Model
{
    use HasUuids;

    protected $fillable = ['id', 'user_id', 'name', 'dosage', 'frequency'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
