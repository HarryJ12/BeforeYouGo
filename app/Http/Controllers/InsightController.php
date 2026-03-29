<?php

namespace App\Http\Controllers;

use App\Models\HealthData;
use App\Models\JournalEntry;
use App\Models\User;
use App\Services\ClaudeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;

class InsightController extends Controller
{
    public function __construct(private readonly ClaudeService $claude) {}

    public function index(): JsonResponse
    {
        $user = User::query()->find(1);

        $profileData = [
            'name' => $user->name,
            'age' => $user->date_of_birth ? Carbon::parse($user->date_of_birth)->age : null,
            'sex' => $user->sex,
            'height' => $user->height_feet !== null ? "{$user->height_feet}'{$user->height_inches}\"" : null,
            'weight_lbs' => $user->weight_lbs,
            'bmi' => $user->bmi,
            'blood_type' => $user->blood_type,
            'allergies' => $user->allergies ?? [],
            'health_goals' => $user->health_goals ?? [],
        ];

        $healthData = HealthData::query()
            ->where('user_id', 1)
            ->where('recorded_at', '>=', now()->subDays(14))
            ->get()
            ->groupBy('metric_type')
            ->map(function ($entries, $type) {
                $values = $entries->pluck('value');

                return [
                    'metric' => $type,
                    'avg' => round($values->avg(), 1),
                    'min' => $values->min(),
                    'max' => $values->max(),
                    'unit' => $entries->first()->unit,
                ];
            })
            ->values()
            ->toArray();

        $journalEntries = JournalEntry::query()
            ->where('user_id', 1)
            ->orderBy('date', 'desc')
            ->limit(5)
            ->get()
            ->map(fn ($e) => [
                'date' => Carbon::parse($e->date)->format('M d'),
                'mood' => $e->mood,
                'symptoms' => $e->symptoms ?? [],
                'activities' => $e->activities ?? [],
                'notes' => $e->notes,
            ])
            ->toArray();

        $insights = $this->claude->generateInsights($profileData, $healthData, $journalEntries);

        return response()->json($insights);
    }
}
