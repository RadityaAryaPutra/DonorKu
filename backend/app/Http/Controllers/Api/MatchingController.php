<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BloodRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MatchingController extends Controller
{
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

        [$eligible, $reason] = $profile->eligibility();

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
            ->whereIn('blood_type', $profile->recipientBloodTypes())
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
}