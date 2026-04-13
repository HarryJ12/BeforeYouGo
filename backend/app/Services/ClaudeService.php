<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ClaudeService
{
    private string $apiKey;

    private string $model;

    public function __construct()
    {
        $this->apiKey = config('services.openai.key', '');
        $this->model = config('services.openai.model', 'gpt-4o');
    }

    public function generateAppointmentPrep(array $context): array
    {
        $system = <<<'SYSTEM'
You are a health preparation assistant for BeforeYouGo, a healthcare literacy app. Generate appointment preparation materials based on the user's profile, real health data, journal entries, medications, and conditions.

The user's profile includes their age, height, weight, BMI, sex, blood type, allergies, and health goals. Factor ALL of this into your recommendations — for example, mention allergies when suggesting medication questions, reference BMI trends if relevant, tailor advice to their stated health goals.

Respond ONLY with valid JSON (no markdown, no backticks, no explanation) in this exact format:
{"whatToMention": ["item1", "item2", "item3", "item4", "item5"], "questionsToAsk": ["question1", "question2", "question3", "question4", "question5"], "summary": "A brief paragraph summarizing key health points to discuss at this appointment"}

Make items specific, actionable, and directly based on the provided health data. Reference actual numbers and trends. Include 4-6 items in each list. Tailor questions to the doctor's specialty.
SYSTEM;

        $userMessage = $this->buildContextMessage($context);

        try {
            $response = $this->callOpenAI($system, [['role' => 'user', 'content' => $userMessage]], 1500);
            $parsed = $this->parseJSON($response);

            if ($parsed && isset($parsed['whatToMention'], $parsed['questionsToAsk'], $parsed['summary'])) {
                return $parsed;
            }
        } catch (\Throwable $e) {
            Log::error('OpenAI appointment prep failed: '.$e->getMessage());
        }

        return [
            'whatToMention' => ['Recent symptoms or changes in health', 'Current medications and dosages', 'Any concerns since your last visit'],
            'questionsToAsk' => ['What follow-up tests do you recommend?', 'Are there any lifestyle changes I should make?', 'When should I schedule my next appointment?'],
            'summary' => 'Come prepared to discuss your current health status and any changes since your last visit.',
        ];
    }

    public function translateMedicalDocument(string $base64Image, string $mediaType = 'image/jpeg'): array
    {
        $system = <<<'SYSTEM'
You are a medical document translator for BeforeYouGo. Convert clinical/medical text from a doctor's visit into plain, easy-to-understand language.

Respond ONLY with valid JSON (no markdown, no backticks) in this exact format:
{"rawText": "The exact text extracted from the document", "whatDoctorFound": "Plain language explanation of findings/diagnosis", "whatThisMeans": "What this means for the patient's health in everyday terms", "whatToDo": "Clear action items and next steps"}

Use simple language a high school student would understand. Avoid medical jargon. Be reassuring but honest. If the document mentions medications, explain what they're for.
SYSTEM;

        try {
            $response = $this->callOpenAIVision($system, $base64Image, $mediaType, 'Extract all text from this medical document, then translate it into plain language.', 2000);
            $parsed = $this->parseJSON($response);

            if ($parsed && isset($parsed['rawText'])) {
                return $parsed;
            }
        } catch (\Throwable $e) {
            Log::error('OpenAI vision translation failed: '.$e->getMessage());
        }

        return [
            'rawText' => 'Unable to extract text from image.',
            'whatDoctorFound' => 'Could not process this document. Please try again with a clearer image.',
            'whatThisMeans' => 'No information available.',
            'whatToDo' => 'Please try uploading a clearer image of the document.',
        ];
    }

    public function translateMedicalText(string $rawText): array
    {
        $system = <<<'SYSTEM'
You are a medical document translator for BeforeYouGo. Convert clinical/medical text into plain, easy-to-understand language.

Respond ONLY with valid JSON (no markdown, no backticks) in this exact format:
{"rawText": "The exact text provided", "whatDoctorFound": "Plain language explanation of findings/diagnosis", "whatThisMeans": "What this means for the patient's health in everyday terms", "whatToDo": "Clear action items and next steps"}

Use simple language a high school student would understand.
SYSTEM;

        try {
            $response = $this->callOpenAI($system, [['role' => 'user', 'content' => $rawText]], 1500);
            $parsed = $this->parseJSON($response);

            if ($parsed) {
                return $parsed;
            }
        } catch (\Throwable $e) {
            Log::error('OpenAI text translation failed: '.$e->getMessage());
        }

        return [
            'rawText' => $rawText,
            'whatDoctorFound' => 'Unable to translate this document.',
            'whatThisMeans' => 'Please consult with your healthcare provider.',
            'whatToDo' => 'Contact your doctor for clarification.',
        ];
    }

    public function generateInsights(array $profileData, array $healthData, array $journalEntries): array
    {
        $system = <<<'SYSTEM'
You are a health insights AI for BeforeYouGo. Analyze the user's profile, health data, and journal entries to generate 2-3 brief, actionable insights.

Consider their BMI, health goals, allergies, age, and sex when generating insights. Tailor advice to their stated goals (e.g. if they want to "Sleep better", prioritize sleep-related insights when sleep data is concerning).

Respond ONLY with valid JSON (no markdown, no backticks) as an array:
[{"title": "Short Title", "body": "1-2 sentence insight with specific advice", "icon": "SF_Symbol_name", "accentColor": "green|yellow|blue|red"}]

Use ONLY these SF Symbol names: heart.fill, figure.walk, moon.fill, leaf.fill, brain.head.profile, drop.fill
Use green for positive trends, blue for informational, yellow for things to watch, red for concerning trends.
Reference actual data points in your insights.
SYSTEM;

        $message = "Profile:\n".json_encode($profileData, JSON_PRETTY_PRINT);
        $message .= "\n\nHealth Data (last 14 days):\n".json_encode($healthData, JSON_PRETTY_PRINT);
        $message .= "\n\nRecent Journal Entries:\n".json_encode($journalEntries, JSON_PRETTY_PRINT);

        try {
            $response = $this->callOpenAI($system, [['role' => 'user', 'content' => $message]], 1000);
            $parsed = $this->parseJSON($response);

            if (is_array($parsed)) {
                return $parsed;
            }
        } catch (\Throwable $e) {
            Log::error('OpenAI insights failed: '.$e->getMessage());
        }

        return [
            ['title' => 'Stay Active', 'body' => 'Keep up with your daily activity goals to support your overall health.', 'icon' => 'figure.walk', 'accentColor' => 'blue'],
        ];
    }

    public function extractInsuranceCard(string $frontBase64, ?string $backBase64 = null): array
    {
        $system = <<<'SYSTEM'
You are an insurance card reader. Extract the following fields from this insurance card image.

Respond ONLY with valid JSON (no markdown, no backticks):
{"provider": "Insurance company name", "planName": "Plan name", "memberID": "Member/Subscriber ID number", "groupNumber": "Group number"}

If a field is not visible, use an empty string. Do not guess or fabricate numbers.
SYSTEM;

        $imageContents = [
            ['type' => 'image_url', 'image_url' => ['url' => "data:image/jpeg;base64,{$frontBase64}"]],
        ];

        if ($backBase64) {
            $imageContents[] = ['type' => 'image_url', 'image_url' => ['url' => "data:image/jpeg;base64,{$backBase64}"]];
        }

        $imageContents[] = ['type' => 'text', 'text' => 'Extract the insurance card information from this image.'];

        try {
            $response = $this->callOpenAIWithContent($system, $imageContents, 500);
            $parsed = $this->parseJSON($response);

            if ($parsed) {
                return $parsed;
            }
        } catch (\Throwable $e) {
            Log::error('OpenAI insurance extraction failed: '.$e->getMessage());
        }

        return ['provider' => '', 'planName' => '', 'memberID' => '', 'groupNumber' => ''];
    }

    public function chat(string $message, array $history, string $healthContext): string
    {
        $system = <<<SYSTEM
You are a caring health companion AI in the BeforeYouGo app. You're conducting a daily check-in with the user about their day and health.

Here is the user's recent health profile from their records:
{$healthContext}

Your goals:
1. Ask about how they're feeling physically and emotionally
2. Note any symptoms, changes, or concerns
3. Ask about activities, diet, sleep, and exercise
4. Be warm, empathetic, and conversational
5. After gathering enough info (3-4 exchanges), provide a brief summary

Keep responses concise (2-3 sentences). Be like a thoughtful friend who understands health well.
SYSTEM;

        $messages = [];
        foreach ($history as $entry) {
            if (isset($entry['role'], $entry['content'])) {
                $messages[] = ['role' => $entry['role'], 'content' => $entry['content']];
            }
        }
        $messages[] = ['role' => 'user', 'content' => $message];

        try {
            return $this->callOpenAI($system, $messages, 500);
        } catch (\Throwable $e) {
            Log::error('OpenAI chat failed: '.$e->getMessage());

            return "I'm here to help with your health check-in. How are you feeling today?";
        }
    }

    public function buildUserProfileContext(User $user): string
    {
        $age = $user->date_of_birth
            ? Carbon::parse($user->date_of_birth)->age
            : 'Unknown';

        $context = "User: {$user->name}, Age: {$age}";

        if ($user->sex) {
            $context .= ", Sex: {$user->sex}";
        }
        if ($user->height_feet !== null && $user->height_inches !== null) {
            $context .= ", Height: {$user->height_feet}'{$user->height_inches}\"";
        }
        if ($user->weight_lbs !== null) {
            $context .= ", Weight: {$user->weight_lbs} lbs";
        }
        if ($user->bmi !== null) {
            $context .= ", BMI: {$user->bmi}";
        }
        if ($user->blood_type) {
            $context .= ", Blood Type: {$user->blood_type}";
        }

        $allergies = $user->allergies ?? [];
        if (count($allergies) > 0) {
            $context .= "\nAllergies: ".implode(', ', $allergies);
        }

        $goals = $user->health_goals ?? [];
        if (count($goals) > 0) {
            $context .= "\nHealth Goals: ".implode(', ', $goals);
        }

        return $context;
    }

    private function callOpenAI(string $system, array $messages, int $maxTokens = 1500): string
    {
        $payload = [
            ['role' => 'system', 'content' => $system],
            ...$messages,
        ];

        $response = Http::withHeaders([
            'Authorization' => 'Bearer '.$this->apiKey,
            'Content-Type' => 'application/json',
        ])->post('https://api.openai.com/v1/chat/completions', [
            'model' => $this->model,
            'max_tokens' => $maxTokens,
            'messages' => $payload,
        ]);

        $data = $response->json();

        return $data['choices'][0]['message']['content'] ?? '';
    }

    private function callOpenAIVision(string $system, string $base64Image, string $mediaType, string $textPrompt, int $maxTokens = 2000): string
    {
        $content = [
            ['type' => 'image_url', 'image_url' => ['url' => "data:{$mediaType};base64,{$base64Image}"]],
            ['type' => 'text', 'text' => $textPrompt],
        ];

        return $this->callOpenAIWithContent($system, $content, $maxTokens);
    }

    private function callOpenAIWithContent(string $system, array $content, int $maxTokens = 1500): string
    {
        $response = Http::withHeaders([
            'Authorization' => 'Bearer '.$this->apiKey,
            'Content-Type' => 'application/json',
        ])->post('https://api.openai.com/v1/chat/completions', [
            'model' => $this->model,
            'max_tokens' => $maxTokens,
            'messages' => [
                ['role' => 'system', 'content' => $system],
                ['role' => 'user', 'content' => $content],
            ],
        ]);

        $data = $response->json();

        return $data['choices'][0]['message']['content'] ?? '';
    }

    private function parseJSON(string $response): ?array
    {
        $cleaned = preg_replace('/^```(?:json)?\s*/m', '', $response);
        $cleaned = preg_replace('/\s*```$/m', '', $cleaned);
        $cleaned = trim($cleaned);

        $decoded = json_decode($cleaned, true);
        if (json_last_error() === JSON_ERROR_NONE) {
            return $decoded;
        }

        if (preg_match('/(\[.*\]|\{.*\})/s', $cleaned, $matches)) {
            $decoded = json_decode($matches[1], true);
            if (json_last_error() === JSON_ERROR_NONE) {
                return $decoded;
            }
        }

        return null;
    }

    private function buildContextMessage(array $context): string
    {
        $message = '';
        foreach ($context as $key => $value) {
            $message .= strtoupper(str_replace('_', ' ', $key)).":\n";
            $message .= is_array($value) ? json_encode($value, JSON_PRETTY_PRINT) : $value;
            $message .= "\n\n";
        }

        return $message;
    }
}
