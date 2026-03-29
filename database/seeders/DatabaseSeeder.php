<?php

namespace Database\Seeders;

use App\Models\Appointment;
use App\Models\Condition;
use App\Models\HealthData;
use App\Models\JournalEntry;
use App\Models\Medication;
use App\Models\PostVisitSummary;
use App\Models\Provider;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $user = User::query()->updateOrCreate(
            ['id' => 1],
            [
                'name' => 'Alex Rivera',
                'email' => 'alex@beforeyougo.app',
                'date_of_birth' => '2003-06-15',
                'location' => 'Lowell, MA',
                'path' => 'healthkit',
                'height_feet' => 5,
                'height_inches' => 10,
                'weight_lbs' => 165.0,
                'bmi' => 23.7,
                'sex' => 'male',
                'blood_type' => 'O+',
                'allergies' => ['Penicillin'],
                'emergency_contact_name' => 'Maria Rivera',
                'emergency_contact_phone' => '978-555-0142',
                'primary_language' => 'English',
                'has_primary_care_doctor' => true,
                'primary_care_doctor_name' => 'Dr. Sarah Chen',
                'health_goals' => ['Stay active', 'Sleep better', 'Prepare for triathlon'],
            ]
        );

        $this->seedHealthData($user->id);
        $this->seedJournalEntries($user->id);
        $this->seedAppointments($user->id);
        $this->seedMedications($user->id);
        $this->seedConditions($user->id);
        $this->seedProviders();
    }

    private function seedHealthData(int $userId): void
    {
        $metrics = [
            'steps' => ['range' => [5000, 10000], 'unit' => 'count'],
            'heart_rate' => ['range' => [62, 85], 'unit' => 'bpm'],
            'sleep_hours' => ['range' => [55, 85], 'unit' => 'hours', 'divisor' => 10],
            'weight' => ['range' => [1640, 1660], 'unit' => 'lbs', 'divisor' => 10],
        ];

        for ($i = 6; $i >= 0; $i--) {
            $date = Carbon::now()->subDays($i)->setTime(8, 0, 0);

            foreach ($metrics as $type => $config) {
                $rawValue = rand($config['range'][0], $config['range'][1]);
                $value = isset($config['divisor']) ? $rawValue / $config['divisor'] : $rawValue;

                HealthData::query()->create([
                    'user_id' => $userId,
                    'metric_type' => $type,
                    'value' => $value,
                    'unit' => $config['unit'],
                    'recorded_at' => $date,
                ]);
            }
        }
    }

    private function seedJournalEntries(int $userId): void
    {
        $entries = [
            [
                'date' => Carbon::now()->subDay(),
                'mood' => 'good',
                'symptoms' => [],
                'activities' => ['Swimming', 'Study session'],
                'notes' => 'Felt strong during swim training.',
                'ai_summary' => 'Good day. Active with swim training. No concerns.',
            ],
            [
                'date' => Carbon::now()->subDays(2),
                'mood' => 'fair',
                'symptoms' => ['Mild headache', 'Fatigue'],
                'activities' => ['Running', 'Research lab'],
                'notes' => 'Woke up with headache. Still ran 5 miles.',
                'ai_summary' => 'Headache and fatigue but maintained activity. Monitor hydration.',
            ],
            [
                'date' => Carbon::now()->subDays(4),
                'mood' => 'great',
                'symptoms' => [],
                'activities' => ['Cycling', 'Hackathon prep'],
                'notes' => 'Great energy. 30-mile bike ride.',
                'ai_summary' => 'Excellent energy. High activity day.',
            ],
        ];

        foreach ($entries as $entry) {
            JournalEntry::query()->create([
                'id' => Str::uuid()->toString(),
                'user_id' => $userId,
                'date' => $entry['date'],
                'mood' => $entry['mood'],
                'symptoms' => $entry['symptoms'],
                'activities' => $entry['activities'],
                'notes' => $entry['notes'],
                'ai_summary' => $entry['ai_summary'],
            ]);
        }
    }

    private function seedAppointments(int $userId): void
    {
        $upcomingId1 = Str::uuid()->toString();
        Appointment::query()->create([
            'id' => $upcomingId1,
            'user_id' => $userId,
            'doctor_name' => 'Dr. Sarah Chen',
            'specialty' => 'Primary Care',
            'date' => Carbon::now()->addDays(4)->format('Y-m-d'),
            'time' => '10:30 AM',
            'reason' => 'Annual physical + blood work review',
            'location' => 'Lowell Community Health Center',
            'is_completed' => false,
        ]);

        Appointment::query()->create([
            'id' => Str::uuid()->toString(),
            'user_id' => $userId,
            'doctor_name' => 'Dr. Michael Torres',
            'specialty' => 'Sports Medicine',
            'date' => Carbon::now()->addDays(12)->format('Y-m-d'),
            'time' => '2:00 PM',
            'reason' => 'Knee check for triathlon training',
            'location' => 'UMass Lowell Health Services',
            'is_completed' => false,
        ]);

        $pastId = Str::uuid()->toString();
        Appointment::query()->create([
            'id' => $pastId,
            'user_id' => $userId,
            'doctor_name' => 'Dr. Emily Walsh',
            'specialty' => 'Dermatology',
            'date' => Carbon::now()->subDays(14)->format('Y-m-d'),
            'time' => '9:00 AM',
            'reason' => 'Skin check',
            'location' => 'Chelmsford Dermatology',
            'is_completed' => true,
        ]);

        PostVisitSummary::query()->create([
            'appointment_id' => $pastId,
            'user_id' => $userId,
            'raw_text' => 'Patient presented for routine skin examination. No suspicious lesions identified. Mild eczema noted on bilateral forearms. Recommend OTC hydrocortisone cream PRN.',
            'what_doctor_found' => 'Your skin check looked great — no concerning spots. The doctor noticed some mild dry, irritated skin (eczema) on both forearms.',
            'what_this_means' => 'This is very common and nothing to worry about. The dry patches on your arms can be managed with simple over-the-counter treatment.',
            'what_to_do' => 'Pick up hydrocortisone cream (1%) from any pharmacy and apply it when the patches feel itchy or inflamed. Keep your skin moisturized, especially after showering.',
        ]);
    }

    private function seedMedications(int $userId): void
    {
        Medication::query()->create([
            'id' => Str::uuid()->toString(),
            'user_id' => $userId,
            'name' => 'Cetirizine',
            'dosage' => '10mg',
            'frequency' => 'Once daily',
        ]);

        Medication::query()->create([
            'id' => Str::uuid()->toString(),
            'user_id' => $userId,
            'name' => 'Vitamin D3',
            'dosage' => '2000 IU',
            'frequency' => 'Once daily',
        ]);
    }

    private function seedConditions(int $userId): void
    {
        Condition::query()->create([
            'user_id' => $userId,
            'name' => 'Seasonal Allergies',
        ]);
    }

    private function seedProviders(): void
    {
        $providers = [
            ['name' => 'Lowell Community Health Center', 'specialty' => 'Primary Care', 'address' => '161 Jackson St, Lowell, MA 01852', 'phone' => '978-937-9700', 'lat' => 42.6451, 'lng' => -71.3154, 'rating' => 4.5, 'insurance' => true],
            ['name' => 'UMass Lowell Health Services', 'specialty' => 'Sports Medicine', 'address' => '100 Pawtucket St, Lowell, MA 01854', 'phone' => '978-934-4991', 'lat' => 42.6573, 'lng' => -71.3246, 'rating' => 4.3, 'insurance' => true],
            ['name' => 'Chelmsford Dermatology', 'specialty' => 'Dermatology', 'address' => '22 Crosby Dr, Chelmsford, MA 01824', 'phone' => '978-256-6055', 'lat' => 42.5984, 'lng' => -71.3673, 'rating' => 4.7, 'insurance' => true],
            ['name' => 'Lowell General Hospital Cardiology', 'specialty' => 'Cardiology', 'address' => '295 Varnum Ave, Lowell, MA 01854', 'phone' => '978-937-6000', 'lat' => 42.6534, 'lng' => -71.3402, 'rating' => 4.6, 'insurance' => true],
            ['name' => 'Northeast Orthopedics', 'specialty' => 'Orthopedics', 'address' => '315 Varnum Ave, Lowell, MA 01854', 'phone' => '978-441-0200', 'lat' => 42.6520, 'lng' => -71.3410, 'rating' => 4.4, 'insurance' => true],
            ['name' => 'Riverside Mental Health', 'specialty' => 'Mental Health', 'address' => '600 Suffolk St, Lowell, MA 01854', 'phone' => '978-458-6538', 'lat' => 42.6412, 'lng' => -71.3289, 'rating' => 4.2, 'insurance' => true],
            ['name' => 'Greater Lowell Urgent Care', 'specialty' => 'Urgent Care', 'address' => '10 Research Pl, North Chelmsford, MA 01863', 'phone' => '978-251-4000', 'lat' => 42.6320, 'lng' => -71.3892, 'rating' => 3.9, 'insurance' => true],
            ['name' => 'Burlington Eye Associates', 'specialty' => 'Ophthalmology', 'address' => '73 Middlesex Turnpike, Burlington, MA 01803', 'phone' => '781-272-2900', 'lat' => 42.5048, 'lng' => -71.1956, 'rating' => 4.8, 'insurance' => true],
            ['name' => 'Lowell Dental Group', 'specialty' => 'Dentistry', 'address' => '30 Calhoun St, Lowell, MA 01852', 'phone' => '978-454-7000', 'lat' => 42.6334, 'lng' => -71.3208, 'rating' => 4.5, 'insurance' => false],
            ['name' => "Women's Health Partners", 'specialty' => 'OB/GYN', 'address' => '10 Industrial Ave, Lowell, MA 01852', 'phone' => '978-458-2100', 'lat' => 42.6280, 'lng' => -71.3421, 'rating' => 4.6, 'insurance' => true],
            ['name' => 'Chelmsford Primary Care', 'specialty' => 'Primary Care', 'address' => '10 Research Pl Ste 200, Chelmsford, MA 01824', 'phone' => '978-256-7711', 'lat' => 42.5990, 'lng' => -71.3680, 'rating' => 4.3, 'insurance' => true],
            ['name' => 'Tewksbury Sports Medicine', 'specialty' => 'Sports Medicine', 'address' => '1900 Main St, Tewksbury, MA 01876', 'phone' => '978-851-4000', 'lat' => 42.6106, 'lng' => -71.2344, 'rating' => 4.4, 'insurance' => true],
            ['name' => 'Merrimack Valley Cardiology', 'specialty' => 'Cardiology', 'address' => '15 Research Pl, North Chelmsford, MA 01863', 'phone' => '978-251-5000', 'lat' => 42.6315, 'lng' => -71.3887, 'rating' => 4.7, 'insurance' => false],
            ['name' => 'Andover Dermatology', 'specialty' => 'Dermatology', 'address' => '385 Lowell St, Andover, MA 01810', 'phone' => '978-470-0551', 'lat' => 42.6584, 'lng' => -71.1375, 'rating' => 4.8, 'insurance' => true],
            ['name' => 'CHA Malden Family Medicine', 'specialty' => 'Primary Care', 'address' => '195 Canal St, Malden, MA 02148', 'phone' => '781-338-7400', 'lat' => 42.4251, 'lng' => -71.0662, 'rating' => 4.1, 'insurance' => true],
            ['name' => 'Lowell Urgent Care', 'specialty' => 'Urgent Care', 'address' => '700 Merrimack St, Lowell, MA 01854', 'phone' => '978-455-5000', 'lat' => 42.6502, 'lng' => -71.3180, 'rating' => 3.8, 'insurance' => false],
            ['name' => 'Mind Matters Counseling', 'specialty' => 'Mental Health', 'address' => '100 Princeton St, Chelmsford, MA 01824', 'phone' => '978-256-9000', 'lat' => 42.5870, 'lng' => -71.3620, 'rating' => 4.5, 'insurance' => true],
            ['name' => 'Nashoba Valley Orthopedics', 'specialty' => 'Orthopedics', 'address' => '45 Resnik Rd, Plymouth, MA 02360', 'phone' => '978-537-7100', 'lat' => 42.5648, 'lng' => -71.7095, 'rating' => 4.6, 'insurance' => true],
        ];

        foreach ($providers as $provider) {
            Provider::query()->create([
                'id' => Str::uuid()->toString(),
                'name' => $provider['name'],
                'specialty' => $provider['specialty'],
                'address' => $provider['address'],
                'phone' => $provider['phone'],
                'latitude' => $provider['lat'],
                'longitude' => $provider['lng'],
                'rating' => $provider['rating'],
                'accepts_insurance' => $provider['insurance'],
            ]);
        }
    }
}
