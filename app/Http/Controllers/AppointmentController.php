<?php

namespace App\Http\Controllers;

use App\Models\Appointment;
use App\Models\AppointmentPrep;
use App\Models\Condition;
use App\Models\HealthData;
use App\Models\JournalEntry;
use App\Models\Medication;
use App\Models\User;
use App\Services\ClaudeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class AppointmentController extends Controller
{
    public function __construct(private readonly ClaudeService $claude) {}

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'id' => 'required|uuid',
            'doctor_name' => 'required|string',
            'specialty' => 'nullable|string',
            'date' => 'required|string',
            'time' => 'required|string',
            'reason' => 'nullable|string',
            'location' => 'nullable|string',
        ]);

        $validated['date'] = date('Y-m-d', strtotime($validated['date']));
        $validated['user_id'] = 1;

        Appointment::query()->updateOrCreate(
            ['id' => $validated['id']],
            $validated
        );

        return response()->json(['success' => true]);
    }

    public function index(): JsonResponse
    {
        $appointments = Appointment::query()
            ->where('user_id', 1)
            ->with(['prep', 'postVisitSummary'])
            ->orderBy('date')
            ->get();

        return response()->json($appointments);
    }

    public function prep(string $id): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($id);

        $cachedPrep = AppointmentPrep::query()
            ->where('appointment_id', $id)
            ->where('updated_at', '>=', now()->subHour())
            ->first();

        if ($cachedPrep) {
            return response()->json([
                'whatToMention' => $cachedPrep->what_to_mention,
                'questionsToAsk' => $cachedPrep->questions_to_ask,
                'summary' => $cachedPrep->summary,
            ]);
        }

        $user = User::query()->find(1);

        $profileContext = $this->claude->buildUserProfileContext($user);

        $healthData = HealthData::query()
            ->where('user_id', 1)
            ->where('recorded_at', '>=', now()->subDays(14))
            ->get()
            ->groupBy('metric_type')
            ->map(function ($entries, $type) {
                $values = $entries->pluck('value');
                $avg = round($values->avg(), 1);
                $min = $values->min();
                $max = $values->max();
                $unit = $entries->first()->unit ?? '';

                return match ($type) {
                    'steps' => 'Steps: avg '.number_format($avg).'/day, range '.number_format($min).'-'.number_format($max),
                    'heart_rate' => "Heart Rate: avg {$avg} bpm, range {$min}-{$max} bpm",
                    'sleep_hours' => "Sleep: avg {$avg} hours/night, range {$min}-{$max} hours",
                    'weight' => "Weight: avg {$avg} lbs, range {$min}-{$max} lbs",
                    default => ucfirst(str_replace('_', ' ', $type)).": avg {$avg} {$unit}",
                };
            })
            ->values()
            ->toArray();

        $journals = JournalEntry::query()
            ->where('user_id', 1)
            ->orderBy('date', 'desc')
            ->limit(5)
            ->get()
            ->map(function ($entry) {
                $dateStr = Carbon::parse($entry->date)->format('M d');
                $symptoms = implode(', ', $entry->symptoms ?? []) ?: 'none';
                $notes = $entry->notes ?? 'No notes';

                return "{$dateStr}: Mood {$entry->mood}. Symptoms: {$symptoms}. Notes: {$notes}";
            })
            ->toArray();

        $medications = Medication::query()
            ->where('user_id', 1)
            ->get()
            ->map(fn ($m) => "{$m->name} {$m->dosage}, {$m->frequency}")
            ->toArray();

        $conditions = Condition::query()
            ->where('user_id', 1)
            ->pluck('name')
            ->toArray();

        $context = [
            'appointment' => "Doctor: {$appointment->doctor_name}, Specialty: {$appointment->specialty}, Reason: {$appointment->reason}, Date: {$appointment->date}, Location: {$appointment->location}",
            'user_profile' => $profileContext,
            'health_data_last_14_days' => $healthData,
            'recent_journal_entries' => $journals,
            'medications' => $medications,
            'conditions' => $conditions,
        ];

        $result = $this->claude->generateAppointmentPrep($context);

        AppointmentPrep::query()->updateOrCreate(
            ['appointment_id' => $id],
            [
                'what_to_mention' => $result['whatToMention'],
                'questions_to_ask' => $result['questionsToAsk'],
                'summary' => $result['summary'],
            ]
        );

        return response()->json($result);
    }

    public function complete(string $id): JsonResponse
    {
        Appointment::query()->findOrFail($id)->update(['is_completed' => true]);

        return response()->json(['success' => true]);
    }
}
