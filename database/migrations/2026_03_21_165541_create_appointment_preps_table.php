<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('appointment_preps', function (Blueprint $table) {
            $table->id();
            $table->uuid('appointment_id');
            $table->foreign('appointment_id')->references('id')->on('appointments')->cascadeOnDelete();
            $table->json('what_to_mention');
            $table->json('questions_to_ask');
            $table->text('summary');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('appointment_preps');
    }
};
