<?php

namespace App\Http\Controllers;

use App\Models\HealthData;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HealthDataController extends Controller
{
    private const UNITS = [
        'steps' => 'count',
        'heart_rate' => 'bpm',
        'sleep_hours' => 'hours',
        'weight' => 'lbs',
    ];

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'date' => 'nullable|string',
            'steps' => 'nullable|numeric',
            'heart_rate' => 'nullable|numeric',
            'sleep_hours' => 'nullable|numeric',
            'weight' => 'nullable|numeric',
        ]);

        $recordedAt = isset($validated['date'])
            ? date('Y-m-d H:i:s', strtotime($validated['date']))
            : now()->toDateTimeString();

        foreach ($validated as $key => $value) {
            if ($key === 'date' || $value === null) {
                continue;
            }

            HealthData::query()->create([
                'user_id' => 1,
                'metric_type' => $key,
                'value' => $value,
                'unit' => self::UNITS[$key] ?? null,
                'recorded_at' => $recordedAt,
            ]);
        }

        return response()->json(['success' => true]);
    }

    public function index(Request $request): JsonResponse
    {
        $days = (int) $request->query('days', 30);

        $data = HealthData::query()
            ->where('user_id', 1)
            ->where('recorded_at', '>=', now()->subDays($days))
            ->orderBy('recorded_at', 'desc')
            ->get();

        return response()->json($data);
    }
}
