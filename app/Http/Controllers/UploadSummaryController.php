<?php

namespace App\Http\Controllers;

use App\Models\PostVisitSummary;
use App\Services\ClaudeService;
use App\Services\GoogleVisionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UploadSummaryController extends Controller
{
    public function __construct(
        private readonly ClaudeService $claude,
        private readonly GoogleVisionService $googleVision
    ) {}

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'image' => 'required|string|max:20000000',
        ]);

        $base64Image = $request->input('image');

        $result = $this->claude->translateMedicalDocument($base64Image);

        if (empty($result['rawText']) || $result['rawText'] === 'Unable to extract text from image.') {
            $rawText = $this->googleVision->extractText($base64Image);
            if ($rawText) {
                $result = $this->claude->translateMedicalText($rawText);
            }
        }

        PostVisitSummary::query()->create([
            'user_id' => 1,
            'raw_text' => $result['rawText'] ?? null,
            'what_doctor_found' => $result['whatDoctorFound'] ?? null,
            'what_this_means' => $result['whatThisMeans'] ?? null,
            'what_to_do' => $result['whatToDo'] ?? null,
        ]);

        return response()->json($result);
    }
}
