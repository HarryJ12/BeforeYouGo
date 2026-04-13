<?php

namespace App\Http\Controllers;

use App\Models\JournalEntry;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class JournalController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'id' => 'required|uuid',
            'date' => 'required|string',
            'mood' => 'required|string|in:good,fair,poor,great',
            'symptoms' => 'nullable|array',
            'activities' => 'nullable|array',
            'notes' => 'nullable|string',
            'ai_summary' => 'nullable|string',
        ]);

        $validated['date'] = date('Y-m-d H:i:s', strtotime($validated['date']));
        $validated['user_id'] = 1;

        JournalEntry::query()->updateOrCreate(
            ['id' => $validated['id']],
            $validated
        );

        return response()->json(['success' => true]);
    }

    public function index(): JsonResponse
    {
        $entries = JournalEntry::query()
            ->where('user_id', 1)
            ->orderBy('date', 'desc')
            ->get();

        return response()->json($entries);
    }
}
