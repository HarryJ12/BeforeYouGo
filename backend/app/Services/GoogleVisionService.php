<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GoogleVisionService
{
    private string $apiKey;

    public function __construct()
    {
        $this->apiKey = config('services.google_vision.key', '');
    }

    public function extractText(string $base64Image): string
    {
        try {
            $response = Http::post(
                "https://vision.googleapis.com/v1/images:annotate?key={$this->apiKey}",
                [
                    'requests' => [
                        [
                            'image' => ['content' => $base64Image],
                            'features' => [['type' => 'TEXT_DETECTION']],
                        ],
                    ],
                ]
            );

            $data = $response->json();

            return $data['responses'][0]['fullTextAnnotation']['text'] ?? '';
        } catch (\Throwable $e) {
            Log::error('Google Vision OCR failed: '.$e->getMessage());

            return '';
        }
    }
}
