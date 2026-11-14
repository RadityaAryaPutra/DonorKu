<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DonorProfileController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/donor-profile', [DonorProfileController::class, 'show']);
    Route::put('/donor-profile', [DonorProfileController::class, 'update']);
});