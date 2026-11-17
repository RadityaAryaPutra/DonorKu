<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BloodRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminBloodRequestController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->ensureAdmin($request);

        $status = $request->query('status', 'menunggu_verifikasi');

        $requests = BloodRequest::with('requester:id,name,phone')
            ->where('status', $status)
            ->oldest()
            ->get();

        return response()->json(['data' => $requests]);
    }

    public function verify(Request $request, BloodRequest $bloodRequest): JsonResponse
    {
        $this->ensureAdmin($request);
        $this->ensurePending($bloodRequest);

        if ($bloodRequest->needed_until->isPast()) {
            return response()->json([
                'message' => 'Batas waktu permintaan sudah lewat, tidak dapat diverifikasi.',
            ], 422);
        }

        $bloodRequest->status = 'aktif';
        $bloodRequest->verified_by = $request->user()->id;
        $bloodRequest->verified_at = now();
        $bloodRequest->rejection_reason = null;
        $bloodRequest->save();

        return response()->json([
            'message' => 'Permintaan diverifikasi dan kini aktif.',
            'data' => $bloodRequest,
        ]);
    }

    public function reject(Request $request, BloodRequest $bloodRequest): JsonResponse
    {
        $this->ensureAdmin($request);
        $this->ensurePending($bloodRequest);

        $data = $request->validate([
            'rejection_reason' => ['required', 'string', 'max:255'],
        ]);

        $bloodRequest->status = 'ditolak';
        $bloodRequest->verified_by = $request->user()->id;
        $bloodRequest->verified_at = now();
        $bloodRequest->rejection_reason = $data['rejection_reason'];
        $bloodRequest->save();

        return response()->json([
            'message' => 'Permintaan ditolak.',
            'data' => $bloodRequest,
        ]);
    }

    private function ensureAdmin(Request $request): void
    {
        abort_unless($request->user()->role === 'admin', 403, 'Hanya admin yang dapat mengakses ini.');
    }

    private function ensurePending(BloodRequest $bloodRequest): void
    {
        abort_unless(
            $bloodRequest->status === 'menunggu_verifikasi',
            422,
            'Permintaan ini sudah diproses sebelumnya.'
        );
    }
}