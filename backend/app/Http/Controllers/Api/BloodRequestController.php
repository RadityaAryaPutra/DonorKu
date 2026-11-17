<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BloodRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BloodRequestController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $this->ensureRequester($request);

        $data = $request->validate([
            'patient_initial' => ['required', 'string', 'max:50'],
            'blood_type' => ['required', 'in:A,B,AB,O'],
            'rhesus' => ['required', 'in:+,-'],
            'units_needed' => ['required', 'integer', 'between:1,10'],
            'hospital_name' => ['required', 'string', 'max:255'],
            'hospital_address' => ['nullable', 'string', 'max:255'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'needed_until' => ['required', 'date', 'after:now'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $bloodRequest = $request->user()->bloodRequests()->create($data);

        return response()->json([
            'message' => 'Permintaan dibuat dan menunggu verifikasi admin.',
            'data' => $bloodRequest->fresh(),
        ], 201);
    }

    public function index(Request $request): JsonResponse
    {
        $this->ensureRequester($request);

        $query = $request->user()->bloodRequests()->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        return response()->json(['data' => $query->get()]);
    }

    public function show(Request $request, BloodRequest $bloodRequest): JsonResponse
    {
        $this->ensureRequester($request);

        abort_unless($bloodRequest->requester_id === $request->user()->id, 404);

        return response()->json(['data' => $bloodRequest]);
    }

    private function ensureRequester(Request $request): void
    {
        abort_unless($request->user()->role === 'pemohon', 403, 'Hanya pemohon yang dapat mengakses ini.');
    }
}