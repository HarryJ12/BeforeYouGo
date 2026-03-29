<?php

namespace App\Http\Controllers;

use App\Models\Condition;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConditionController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string',
        ]);

        $validated['user_id'] = 1;

        $condition = Condition::query()->create($validated);

        return response()->json($condition, 201);
    }

    public function index(): JsonResponse
    {
        $conditions = Condition::query()
            ->where('user_id', 1)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($conditions);
    }

    public function destroy(string $id): JsonResponse
    {
        Condition::query()->findOrFail($id)->delete();

        return response()->json(['success' => true]);
    }
}
