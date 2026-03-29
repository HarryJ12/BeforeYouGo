<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_data', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('metric_type');
            $table->decimal('value', 10, 2);
            $table->string('unit')->nullable();
            $table->timestamp('recorded_at');
            $table->timestamps();

            $table->index(['user_id', 'metric_type', 'recorded_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_data');
    }
};
