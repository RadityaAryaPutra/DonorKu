<?php

use App\Http\Controllers\Api\AdminBloodRequestController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BloodRequestController;
use App\Http\Controllers\Api\DonorProfileController;
use App\Http\Controllers\Api\DonorResponseController;
use App\Http\Controllers\Api\MatchingController;
use App\Http\Controllers\Api\RequesterResponseController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/donor-profile', [DonorProfileController::class, 'show']);
    Route::put('/donor-profile', [DonorProfileController::class, 'update']);

    Route::post('/blood-requests', [BloodRequestController::class, 'store']);
    Route::get('/blood-requests', [BloodRequestController::class, 'index']);
    Route::get('/blood-requests/{bloodRequest}', [BloodRequestController::class, 'show']);

    Route::get('/admin/blood-requests', [AdminBloodRequestController::class, 'index']);
    Route::post('/admin/blood-requests/{bloodRequest}/verify', [AdminBloodRequestController::class, 'verify']);
    Route::post('/admin/blood-requests/{bloodRequest}/reject', [AdminBloodRequestController::class, 'reject']);

    Route::get('/matching/requests', [MatchingController::class, 'nearby']);

    Route::post('/blood-requests/{bloodRequest}/respond', [DonorResponseController::class, 'store']);

    Route::get('/blood-requests/{bloodRequest}/responses', [RequesterResponseController::class, 'index']);
    Route::post('/responses/{requestResponse}/approve', [RequesterResponseController::class, 'approve']);
    Route::post('/responses/{requestResponse}/reject', [RequesterResponseController::class, 'reject']);
    Route::post('/responses/{requestResponse}/complete', [RequesterResponseController::class, 'complete']);
});