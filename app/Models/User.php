<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'date_of_birth',
        'location',
        'path',
        'height_feet',
        'height_inches',
        'weight_lbs',
        'bmi',
        'sex',
        'blood_type',
        'allergies',
        'emergency_contact_name',
        'emergency_contact_phone',
        'primary_language',
        'has_primary_care_doctor',
        'primary_care_doctor_name',
        'health_goals',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'date_of_birth' => 'date',
            'allergies' => 'array',
            'health_goals' => 'array',
            'has_primary_care_doctor' => 'boolean',
            'weight_lbs' => 'float',
            'bmi' => 'float',
        ];
    }

    public function healthData(): HasMany
    {
        return $this->hasMany(HealthData::class);
    }

    public function journalEntries(): HasMany
    {
        return $this->hasMany(JournalEntry::class);
    }

    public function appointments(): HasMany
    {
        return $this->hasMany(Appointment::class);
    }

    public function medications(): HasMany
    {
        return $this->hasMany(Medication::class);
    }

    public function conditions(): HasMany
    {
        return $this->hasMany(Condition::class);
    }

    public function insuranceInfo(): HasOne
    {
        return $this->hasOne(InsuranceInfo::class);
    }

    public function dailySummaries(): HasMany
    {
        return $this->hasMany(DailySummary::class);
    }
}
