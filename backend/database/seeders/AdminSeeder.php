<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@donorku.test'],
            [
                'name' => 'Admin DonorKu',
                'phone' => '080000000000',
                'role' => 'admin',
                'password' => 'password123',
            ]
        );
    }
}