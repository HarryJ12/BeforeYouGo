<?php

namespace App\Http\Controllers;

use App\Models\Provider;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProviderController extends Controller
{
    private const USER_LATITUDE = 42.6334;

    private const USER_LONGITUDE = -71.3162;

    public function search(Request $request): JsonResponse
    {
        $specialty = $request->query('specialty');
        $distance = (float) $request->query('distance', 50);
        $insuranceOnly = filter_var($request->query('insurance_only', false), FILTER_VALIDATE_BOOLEAN);

        $query = Provider::query();

        if ($specialty) {
            $query->where('specialty', 'LIKE', "%{$specialty}%");
        }

        if ($insuranceOnly) {
            $query->where('accepts_insurance', true);
        }

        $providers = $query->get();

        $results = $providers
            ->map(function (Provider $provider) {
                $dist = $this->haversineDistance(
                    self::USER_LATITUDE,
                    self::USER_LONGITUDE,
                    (float) $provider->latitude,
                    (float) $provider->longitude
                );

                return [
                    'id' => $provider->id,
                    'name' => $provider->name,
                    'specialty' => $provider->specialty,
                    'distance' => round($dist, 1),
                    'rating' => $provider->rating,
                    'acceptsInsurance' => $provider->accepts_insurance,
                    'address' => $provider->address,
                    'phone' => $provider->phone,
                    'latitude' => $provider->latitude,
                    'longitude' => $provider->longitude,
                    '_distance' => $dist,
                ];
            })
            ->filter(fn ($p) => $p['_distance'] <= $distance)
            ->sortBy('_distance')
            ->take(20)
            ->values()
            ->map(function ($p) {
                unset($p['_distance']);

                return $p;
            });

        return response()->json($results);
    }

    private function haversineDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadiusMiles = 3958.8;

        $lat1Rad = deg2rad($lat1);
        $lat2Rad = deg2rad($lat2);
        $deltaLat = deg2rad($lat2 - $lat1);
        $deltaLon = deg2rad($lon2 - $lon1);

        $a = sin($deltaLat / 2) ** 2 +
            cos($lat1Rad) * cos($lat2Rad) * sin($deltaLon / 2) ** 2;

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadiusMiles * $c;
    }
}
