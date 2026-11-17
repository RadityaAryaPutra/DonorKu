<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BloodRequest;
use App\Models\DonationHistory;
use App\Models\DonorProfile;
use App\Models\RequestResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RequesterResponseController extends Controller
{
    public function index(Request $request, BloodRequest $bloodRequest): JsonResponse
    {
        $this->ensureRequester($request);
        abort_unless($bloodRequest->requester_id === $request->user()->id, 404);

        $responses = $bloodRequest->responses()
            ->with('donor.donorProfile')
            ->latest()
            ->get()
            ->map(function ($response) use ($bloodRequest) {
                $donor = $response->donor;
                $profile = $donor->donorProfile;
                $showContact = in_array($response->status, ['disetujui', 'selesai'], true);

                return [
                    'id' => $response->id,
                    'status' => $response->status,
                    'donor' => [
                        'name' => $donor->name,
                        'blood_type' => $profile?->blood_type,
                        'rhesus' => $profile?->rhesus,
                        'distance_km' => ($profile && $profile->latitude !== null)
                            ? $this->distanceKm(
                                $bloodRequest->latitude,
                                $bloodRequest->longitude,
                                $profile->latitude,
                                $profile->longitude
                            )
                            : null,
                        'phone' => $showContact ? $donor->phone : null,
                    ],
                ];
            });

        return response()->json(['data' => $responses]);
    }

    public function approve(Request $request, RequestResponse $requestResponse): JsonResponse
    {
        $bloodRequest = $this->ownedRequest($request, $requestResponse);

        abort_unless($requestResponse->status === 'bersedia', 422, 'Pendonor ini tidak dalam status menunggu persetujuan.');
        abort_unless($bloodRequest->status === 'aktif', 422, 'Permintaan ini sudah tidak aktif.');

        $committed = $bloodRequest->responses()->where('status', 'disetujui')->count();
        abort_unless(
            $committed + $bloodRequest->units_fulfilled < $bloodRequest->units_needed,
            422,
            'Kuota pendonor untuk permintaan ini sudah penuh.'
        );

        $requestResponse->status = 'disetujui';
        $requestResponse->save();

        return response()->json([
            'message' => 'Pendonor disetujui.',
            'data' => $requestResponse,
        ]);
    }

    public function reject(Request $request, RequestResponse $requestResponse): JsonResponse
    {
        $this->ownedRequest($request, $requestResponse);

        abort_unless($requestResponse->status === 'bersedia', 422, 'Pendonor ini tidak dalam status menunggu persetujuan.');

        $requestResponse->status = 'ditolak';
        $requestResponse->save();

        return response()->json([
            'message' => 'Pendonor ditolak.',
            'data' => $requestResponse,
        ]);
    }

    public function complete(Request $request, RequestResponse $requestResponse): JsonResponse
    {
        $bloodRequest = $this->ownedRequest($request, $requestResponse);

        abort_unless(
            $requestResponse->status === 'disetujui',
            422,
            'Hanya pendonor yang sudah disetujui yang dapat ditandai selesai.'
        );

        DB::transaction(function () use ($requestResponse, $bloodRequest) {
            $locked = BloodRequest::lockForUpdate()->find($bloodRequest->id);

            $requestResponse->status = 'selesai';
            $requestResponse->save();

            DonationHistory::forceCreate([
                'donor_id' => $requestResponse->donor_id,
                'blood_request_id' => $locked->id,
                'donated_at' => today()->toDateString(),
                'units' => 1,
            ]);

            DonorProfile::where('user_id', $requestResponse->donor_id)
                ->update(['last_donation_date' => today()->toDateString()]);

            $locked->units_fulfilled = $locked->units_fulfilled + 1;

            if ($locked->units_fulfilled >= $locked->units_needed) {
                $locked->status = 'terpenuhi';
            }

            $locked->save();
        });

        return response()->json([
            'message' => 'Donor ditandai selesai.',
            'data' => $bloodRequest->fresh(),
        ]);
    }

    private function ensureRequester(Request $request): void
    {
        abort_unless($request->user()->role === 'pemohon', 403, 'Hanya pemohon yang dapat mengakses ini.');
    }

    private function ownedRequest(Request $request, RequestResponse $requestResponse): BloodRequest
    {
        $this->ensureRequester($request);

        $bloodRequest = $requestResponse->bloodRequest;
        abort_unless($bloodRequest->requester_id === $request->user()->id, 404);

        return $bloodRequest;
    }

    private function distanceKm(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) ** 2;

        return round($earthRadius * 2 * asin(sqrt($a)), 1);
    }
}