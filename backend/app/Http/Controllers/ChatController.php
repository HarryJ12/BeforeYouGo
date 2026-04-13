<?php

namespace App\Http\Controllers;

use App\Models\HealthData;
use App\Models\JournalEntry;
use App\Models\User;
use App\Services\ClaudeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class ChatController extends Controller
{
    public function __construct(private readonly ClaudeService $claude) {}

    public function message(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'message' => 'required|string',
            'history' => 'nullable|array',
            'history.*.role' => 'required|string|in:user,assistant',
            'history.*.content' => 'required|string',
        ]);

        $user = User::query()->find(1);
        $healthContext = $this->claude->buildUserProfileContext($user);

        $recentHealth = HealthData::query()
            ->where('user_id', 1)
            ->where('recorded_at', '>=', now()->subDays(7))
            ->get()
            ->groupBy('metric_type')
            ->map(fn ($entries, $type) => ucfirst(str_replace('_', ' ', $type)).': avg '.round($entries->pluck('value')->avg(), 1).' '.($entries->first()->unit ?? ''))
            ->values()
            ->implode(', ');

        if ($recentHealth) {
            $healthContext .= "\nRecent health data: {$recentHealth}";
        }

        $recentJournal = JournalEntry::query()
            ->where('user_id', 1)
            ->orderBy('date', 'desc')
            ->limit(2)
            ->get()
            ->map(fn ($e) => Carbon::parse($e->date)->format('M d').": Mood {$e->mood}")
            ->implode(', ');

        if ($recentJournal) {
            $healthContext .= "\nRecent journal: {$recentJournal}";
        }

        $response = $this->claude->chat(
            $validated['message'],
            $validated['history'] ?? [],
            $healthContext
        );

        return response()->json(['response' => $response]);
    }
}
