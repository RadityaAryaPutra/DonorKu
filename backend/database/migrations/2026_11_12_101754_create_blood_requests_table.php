<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('blood_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('requester_id')->constrained('users')->cascadeOnDelete();
            $table->string('patient_initial', 50);
            $table->enum('blood_type', ['A', 'B', 'AB', 'O']);
            $table->enum('rhesus', ['+', '-']);
            $table->unsignedTinyInteger('units_needed');
            $table->unsignedTinyInteger('units_fulfilled')->default(0);
            $table->string('hospital_name');
            $table->string('hospital_address')->nullable();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->dateTime('needed_until');
            $table->text('notes')->nullable();
            $table->enum('status', [
                'menunggu_verifikasi',
                'aktif',
                'terpenuhi',
                'ditolak',
                'kedaluwarsa',
            ])->default('menunggu_verifikasi');
            $table->foreignId('verified_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('verified_at')->nullable();
            $table->string('rejection_reason')->nullable();
            $table->timestamps();

            $table->index(['status', 'needed_until']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('blood_requests');
    }
};