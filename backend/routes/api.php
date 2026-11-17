<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DonorProfileController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\BloodRequestController;

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
});