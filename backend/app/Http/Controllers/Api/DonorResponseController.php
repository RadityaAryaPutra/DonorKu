<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BloodRequest;
use App\Models\RequestResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DonorResponseController extends Controller
{
    public function store(Request $request, BloodRequest $bloodRequest): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'pendonor', 403, 'Hanya pendonor yang dapat mengakses ini.');

        $profile = $user->donorProfile;
        abort_unless($profile, 422, 'Lengkapi profil donor terlebih dahulu.');

        [$eligible, $reason] = $profile->eligibility();
        abort_unless($eligible, 422, $reason);

        abort_unless(
            $bloodRequest->status === 'aktif'
                && $bloodRequest->needed_until->isFuture()
                && $bloodRequest->units_fulfilled < $bloodRequest->units_needed,
            422,
            'Permintaan ini tidak lagi menerima pendonor.'
        );

        abort_unless(
            $profile->canDonateTo($bloodRequest),
            422,
            'Golongan darahmu tidak cocok dengan permintaan ini.'
        );

        $response = RequestResponse::where('blood_request_id', $bloodRequest->id)
            ->where('donor_id', $user->id)
            ->first();

        if ($response && $response->status !== 'dibatalkan') {
            return response()->json([
                'message' => 'Kamu sudah menyatakan bersedia untuk permintaan ini.',
            ], 409);
        }

        if ($response) {
            $response->status = 'bersedia';
            $response->save();
        } else {
            $response = RequestResponse::forceCreate([
                'blood_request_id' => $bloodRequest->id,
                'donor_id' => $user->id,
                'status' => 'bersedia',
            ]);
        }

        $requester = $bloodRequest->requester;

        return response()->json([
            'message' => 'Terima kasih, kesediaanmu sudah dicatat.',
            'data' => $response,
            'contact' => [
                'name' => $requester->name,
                'phone' => $requester->phone,
            ],
        ], 201);
    }
}