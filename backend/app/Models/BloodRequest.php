<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'patient_initial',
    'blood_type',
    'rhesus',
    'units_needed',
    'hospital_name',
    'hospital_address',
    'latitude',
    'longitude',
    'needed_until',
    'notes',
])]
class BloodRequest extends Model
{
    protected function casts(): array
    {
        return [
            'units_needed' => 'integer',
            'units_fulfilled' => 'integer',
            'latitude' => 'float',
            'longitude' => 'float',
            'needed_until' => 'datetime',
            'verified_at' => 'datetime',
        ];
    }

    public function requester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requester_id');
    }

    public function verifier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'verified_by');
    }

    public function responses(): HasMany
    {
        return $this->hasMany(RequestResponse::class);
    }
}