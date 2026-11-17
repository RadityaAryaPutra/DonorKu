<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BloodRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MatchingController extends Controller
{
    // Jeda minimal antar donor (hari).
    private const DONATION_INTERVAL_DAYS = 90;

    // Golongan darah penerima yang boleh menerima dari pendonor (ABO).
    private const ABO_RECIPIENTS = [
        'O' => ['O', 'A', 'B', 'AB'],
        'A' => ['A', 'AB'],
        'B' => ['B', 'AB'],
        'AB' => ['AB'],
    ];

    public function nearby(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'pendonor', 403, 'Hanya pendonor yang dapat mengakses ini.');

        $profile = $user->donorProfile;

        if (! $profile || $profile->latitude === null || $profile->longitude === null) {
            return response()->json([
                'message' => 'Lengkapi profil donor dan lokasimu terlebih dahulu.',
            ], 422);
        }

        $radius = (float) $request->query('radius', 5);
        $radius = max(1, min($radius, 50));

        [$eligible, $reason] = $this->eligibility($profile);

        if (! $eligible) {
            return response()->json([
                'eligible' => false,
                'reason' => $reason,
                'data' => [],
            ]);
        }

        $query = BloodRequest::query()
            ->selectRaw(
                'blood_requests.*, ST_Distance_Sphere(POINT(longitude, latitude), POINT(?, ?)) / 1000 as distance_km',
                [$profile->longitude, $profile->latitude]
            )
            ->where('status', 'aktif')
            ->where('needed_until', '>', now())
            ->whereColumn('units_fulfilled', '<', 'units_needed')
            ->whereIn('blood_type', self::ABO_RECIPIENTS[$profile->blood_type])
            ->having('distance_km', '<=', $radius)
            ->orderBy('distance_km');

        // Donor Rh+ hanya boleh ke penerima Rh+. Donor Rh- boleh ke keduanya.
        if ($profile->rhesus === '+') {
            $query->where('rhesus', '+');
        }

        $data = $query->get()->map(function ($item) {
            return [
                'id' => $item->id,
                'blood_type' => $item->blood_type,
                'rhesus' => $item->rhesus,
                'units_needed' => $item->units_needed,
                'units_fulfilled' => $item->units_fulfilled,
                'hospital_name' => $item->hospital_name,
                'hospital_address' => $item->hospital_address,
                'needed_until' => $item->needed_until,
                'distance_km' => round((float) $item->distance_km, 1),
            ];
        });

        return response()->json([
            'eligible' => true,
            'radius_km' => $radius,
            'data' => $data,
        ]);
    }

    private function eligibility($profile): array
    {
        if (! $profile->is_available) {
            return [false, 'Kamu sedang menonaktifkan status bersedia dihubungi.'];
        }

        if ($profile->last_donation_date) {
            $nextDate = $profile->last_donation_date->copy()->addDays(self::DONATION_INTERVAL_DAYS);

            if ($nextDate->isFuture()) {
                return [false, 'Kamu baru bisa mendonor lagi mulai '.$nextDate->toDateString().'.'];
            }
        }

        return [true, null];
    }
}