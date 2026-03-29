<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class ProfileController extends Controller
{
    public function show(): JsonResponse
    {
        $user = User::query()->findOrFail(1);

        $age = $user->date_of_birth
            ? Carbon::parse($user->date_of_birth)->age
            : null;

        return response()->json([
            'name' => $user->name,
            'dateOfBirth' => $user->date_of_birth?->format('Y-m-d'),
            'location' => $user->location,
            'path' => $user->path,
            'age' => $age,
            'heightFeet' => $user->height_feet,
            'heightInches' => $user->height_inches,
            'weightLbs' => $user->weight_lbs,
            'bmi' => $user->bmi,
            'sex' => $user->sex,
            'bloodType' => $user->blood_type,
            'allergies' => $user->allergies ?? [],
            'emergencyContactName' => $user->emergency_contact_name,
            'emergencyContactPhone' => $user->emergency_contact_phone,
            'primaryLanguage' => $user->primary_language,
            'hasPrimaryCareDoctor' => $user->has_primary_care_doctor,
            'primaryCareDoctorName' => $user->primary_care_doctor_name,
            'healthGoals' => $user->health_goals ?? [],
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'nullable|string',
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

        $user = User::query()->findOrFail(1);
        $user->fill($data);

        if (isset($data['weight_lbs']) || isset($data['height_feet']) || isset($data['height_inches'])) {
            $totalInches = (($user->height_feet ?? 0) * 12) + ($user->height_inches ?? 0);
            if ($totalInches > 0 && $user->weight_lbs) {
                $user->bmi = round($user->weight_lbs / ($totalInches ** 2) * 703, 1);
            }
        }

        $user->save();

        return response()->json(['success' => true]);
    }
}
