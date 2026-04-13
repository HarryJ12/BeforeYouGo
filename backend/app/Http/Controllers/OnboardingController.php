<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OnboardingController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string',
            'date_of_birth' => 'nullable|string',
            'location' => 'nullable|string',
            'path' => 'nullable|string|in:healthkit,journal',
            'height_feet' => 'nullable|integer',
            'height_inches' => 'nullable|integer',
            'weight_lbs' => 'nullable|numeric',
            'sex' => 'nullable|string',
            'blood_type' => 'nullable|string',
            'allergies' => 'nullable|array',
            'emergency_contact_name' => 'nullable|string',
            'emergency_contact_phone' => 'nullable|string',
            'primary_language' => 'nullable|string',
            'has_primary_care_doctor' => 'nullable|boolean',
            'primary_care_doctor_name' => 'nullable|string',
            'health_goals' => 'nullable|array',
        ]);

        $data = array_filter($validated, fn ($v) => $v !== null);

        if (isset($data['date_of_birth'])) {
            $data['date_of_birth'] = date('Y-m-d', strtotime($data['date_of_birth']));
        }

        $data['bmi'] = $this->computeBmi($data);

        User::query()->updateOrCreate(['id' => 1], $data);

        return response()->json(['success' => true, 'user_id' => 1]);
    }

    private function computeBmi(array $data): ?float
    {
        $heightFeet = $data['height_feet'] ?? null;
        $heightInches = $data['height_inches'] ?? null;
        $weightLbs = $data['weight_lbs'] ?? null;

        if ($heightFeet === null || $heightInches === null || $weightLbs === null) {
            return null;
        }

        $totalInches = ($heightFeet * 12) + $heightInches;

        if ($totalInches === 0) {
            return null;
        }

        return round($weightLbs / ($totalInches ** 2) * 703, 1);
    }
}
