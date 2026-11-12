<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('request_responses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('blood_request_id')->constrained()->cascadeOnDelete();
            $table->foreignId('donor_id')->constrained('users')->cascadeOnDelete();
            $table->enum('status', [
                'bersedia',
                'disetujui',
                'ditolak',
                'selesai',
                'dibatalkan',
            ])->default('bersedia');
            $table->timestamps();

            $table->unique(['blood_request_id', 'donor_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('request_responses');
    }
};