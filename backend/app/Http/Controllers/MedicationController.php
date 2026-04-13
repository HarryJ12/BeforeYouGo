<?php

namespace App\Http\Controllers;

use App\Models\Medication;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MedicationController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string',
            'dosage' => 'nullable|string',
            'frequency' => 'nullable|string',
        ]);

        $validated['user_id'] = 1;

        $medication = Medication::query()->create($validated);

        return response()->json($medication, 201);
    }

    public function index(): JsonResponse
    {
        $medications = Medication::query()
            ->where('user_id', 1)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($medications);
    }

    public function destroy(string $id): JsonResponse
    {
        Medication::query()->findOrFail($id)->delete();

        return response()->json(['success' => true]);
    }
}
