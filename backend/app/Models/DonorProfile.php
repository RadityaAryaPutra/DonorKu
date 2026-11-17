<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'blood_type',
    'rhesus',
    'latitude',
    'longitude',
    'last_donation_date',
    'is_available',
])]
class DonorProfile extends Model
{
    public const DONATION_INTERVAL_DAYS = 90;

    private const ABO_RECIPIENTS = [
        'O' => ['O', 'A', 'B', 'AB'],
        'A' => ['A', 'AB'],
        'B' => ['B', 'AB'],
        'AB' => ['AB'],
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'float',
            'longitude' => 'float',
            'last_donation_date' => 'date',
            'is_available' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return array{0: bool, 1: string|null}
     */
    public function eligibility(): array
    {
        if (! $this->is_available) {
            return [false, 'Kamu sedang menonaktifkan status bersedia dihubungi.'];
        }

        if ($this->last_donation_date) {
            $nextDate = $this->last_donation_date->copy()->addDays(self::DONATION_INTERVAL_DAYS);

            if ($nextDate->isFuture()) {
                return [false, 'Kamu baru bisa mendonor lagi mulai '.$nextDate->toDateString().'.'];
            }
        }

        return [true, null];
    }

    public function recipientBloodTypes(): array
    {
        return self::ABO_RECIPIENTS[$this->blood_type];
    }

    public function canDonateTo(BloodRequest $request): bool
    {
        return in_array($request->blood_type, $this->recipientBloodTypes(), true)
            && ($this->rhesus === '-' || $request->rhesus === '+');
    }
}