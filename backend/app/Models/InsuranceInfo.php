<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InsuranceInfo extends Model
{
    protected $table = 'insurance_info';

    protected $fillable = [
        'user_id',
        'provider',
        'plan_name',
        'member_id',
        'group_number',
        'policy_holder_name',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
