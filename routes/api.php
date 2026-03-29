<?php

use App\Http\Controllers\AppointmentController;
use App\Http\Controllers\ChatController;
use App\Http\Controllers\ConditionController;
use App\Http\Controllers\HealthDataController;
use App\Http\Controllers\InsightController;
use App\Http\Controllers\InsuranceController;
use App\Http\Controllers\JournalController;
use App\Http\Controllers\MedicationController;
use App\Http\Controllers\OnboardingController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\ProviderController;
use App\Http\Controllers\UploadSummaryController;
use Illuminate\Support\Facades\Route;

Route::post('/onboarding', [OnboardingController::class, 'store']);

Route::post('/health-data', [HealthDataController::class, 'store']);
Route::get('/health-data', [HealthDataController::class, 'index']);

Route::post('/journal-entry', [JournalController::class, 'store']);
Route::get('/journal-entries', [JournalController::class, 'index']);

Route::post('/appointments', [AppointmentController::class, 'store']);
Route::get('/appointments', [AppointmentController::class, 'index']);
Route::get('/appointments/{id}/prep', [AppointmentController::class, 'prep']);
Route::post('/appointments/{id}/complete', [AppointmentController::class, 'complete']);

Route::post('/upload-summary', [UploadSummaryController::class, 'store']);

Route::get('/providers/search', [ProviderController::class, 'search']);

Route::post('/insurance-card', [InsuranceController::class, 'store']);
Route::get('/insurance', [InsuranceController::class, 'show']);

Route::get('/insights', [InsightController::class, 'index']);

Route::post('/medications', [MedicationController::class, 'store']);
Route::get('/medications', [MedicationController::class, 'index']);
Route::delete('/medications/{id}', [MedicationController::class, 'destroy']);

Route::post('/conditions', [ConditionController::class, 'store']);
Route::get('/conditions', [ConditionController::class, 'index']);
Route::delete('/conditions/{id}', [ConditionController::class, 'destroy']);

Route::post('/chat', [ChatController::class, 'message']);

Route::get('/profile', [ProfileController::class, 'show']);
Route::put('/profile', [ProfileController::class, 'update']);
