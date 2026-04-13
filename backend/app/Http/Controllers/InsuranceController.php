<?php

namespace App\Http\Controllers;

use App\Models\InsuranceInfo;
use App\Services\ClaudeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InsuranceController extends Controller
{
    public function __construct(private readonly ClaudeService $claude) {}

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'front_image' => 'required|string|max:20000000',
            'back_image' => 'nullable|string|max:20000000',
        ]);

        $result = $this->claude->extractInsuranceCard(
            $request->input('front_image'),
            $request->input('back_image')
        );

        InsuranceInfo::query()->updateOrCreate(
            ['user_id' => 1],
            [
                'provider' => $result['provider'] ?? null,
                'plan_name' => $result['planName'] ?? null,
                'member_id' => $result['memberID'] ?? null,
                'group_number' => $result['groupNumber'] ?? null,
            ]
        );

        return response()->json($result);
    }

    public function show(): JsonResponse
    {
        $info = InsuranceInfo::query()->where('user_id', 1)->first();

        if (! $info) {
            return response()->json((object) []);
        }

        return response()->json([
            'provider' => $info->provider,
            'planName' => $info->plan_name,
            'memberID' => $info->member_id,
            'groupNumber' => $info->group_number,
        ]);
    }
}
