<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DonorProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $this->ensureDonor($request);

        return response()->json([
            'profile' => $request->user()->donorProfile,
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $this->ensureDonor($request);

        $data = $request->validate([
            'blood_type' => ['required', 'in:A,B,AB,O'],
            'rhesus' => ['required', 'in:+,-'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'last_donation_date' => ['nullable', 'date', 'before_or_equal:today'],
            'is_available' => ['sometimes', 'boolean'],
        ]);

        $profile = $request->user()->donorProfile()->updateOrCreate([], $data);

        return response()->json([
            'message' => 'Profil donor disimpan.',
            'profile' => $profile,
        ]);
    }

    private function ensureDonor(Request $request): void
    {
        abort_unless(
            $request->user()->role === 'pendonor',
            403,
            'Hanya pendonor yang memiliki profil donor.'
        );
    }
}