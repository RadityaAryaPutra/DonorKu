<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('donation_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('donor_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('blood_request_id')->nullable()->constrained()->nullOnDelete();
            $table->date('donated_at');
            $table->unsignedTinyInteger('units')->default(1);
            $table->timestamps();

            $table->index(['donor_id', 'donated_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('donation_histories');
    }
};