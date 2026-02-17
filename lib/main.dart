import 'package:flutter/material.dart';

void main() {
  runApp(const SmartFoodApp());
}

/* ---------------- DATA MODEL ---------------- */

class Food {
  final String name;
  final double weightKg; // from load cell
  final String location;
  final double temperature;
  final DateTime preparedTime;
  String status;

  Food({
    required this.name,
    required this.weightKg,
    required this.location,
    required this.temperature,
    required this.preparedTime,
    this.status = 'Available',
  });

  // Convert kg → plates (logic)
  int get plates => (weightKg / 0.35).round();

  // Safe time logic (simple)
  Duration get safeDuration {
    if (temperature <= 10) {
      return const Duration(hours: 8);
    } else {
      return const Duration(hours: 4);
    }
  }

  Duration get remainingTime {
    final expiry = preparedTime.add(safeDuration);
    return expiry.difference(DateTime.now());
  }

  bool get isExpired => remainingTime.isNegative;

  bool get isUrgent =>
      remainingTime.inMinutes <= (safeDuration.inMinutes * 0.3);

  Color get statusColor {
    if (isExpired) return Colors.red;
    if (isUrgent) return Colors.orange;
    return Colors.green;
  }

  String get displayStatus {
    if (isExpired) return 'Expired';
    if (status == 'Requested') return 'Requested';
    if (isUrgent) return 'Urgent';
    return 'Available';
  }
}

/* ---------------- GLOBAL STORAGE (PROTOTYPE) ---------------- */

List<Food> foodList = [];

/* ---------------- APP ROOT ---------------- */

class SmartFoodApp extends StatelessWidget {
  const SmartFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Food Surplus',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const RoleSelectionScreen(),
    );
  }
}

/* ---------------- ROLE SELECTION ---------------- */

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Food Surplus System')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.food_bank, size: 100, color: Colors.green),
          const SizedBox(height: 20),
          const Text(
            'Reduce Food Waste using IoT',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),

          Card(
            child: ListTile(
              leading: const Icon(Icons.store, color: Colors.green),
              title: const Text('Donor'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DonorDashboard()),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.volunteer_activism,
                color: Colors.green,
              ),
              title: const Text('Receiver'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReceiverDashboard()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- DONOR DASHBOARD ---------------- */

class DonorDashboard extends StatelessWidget {
  const DonorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donor Dashboard')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Food Donation'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddFoodScreen()),
            );
          },
        ),
      ),
    );
  }
}

/* ---------------- ADD FOOD ---------------- */

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final nameController = TextEditingController();
  final locationController = TextEditingController();

  // Simulated IoT values
  final double simulatedWeightKg = 5.0;
  final double simulatedTemp = 6.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Food Donation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Food Name'),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Pickup Location'),
            ),
            const SizedBox(height: 20),

            const Text(
              'IoT Sensor Data (Auto)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(Icons.scale, color: Colors.green),
              title: const Text('Weight'),
              trailing: Text('$simulatedWeightKg kg'),
            ),
            ListTile(
              leading: const Icon(Icons.thermostat, color: Colors.green),
              title: const Text('Temperature'),
              trailing: Text('$simulatedTemp °C'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                foodList.add(
                  Food(
                    name: nameController.text,
                    weightKg: simulatedWeightKg,
                    location: locationController.text,
                    temperature: simulatedTemp,
                    preparedTime: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Submit Donation'),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- RECEIVER DASHBOARD ---------------- */

class ReceiverDashboard extends StatefulWidget {
  const ReceiverDashboard({super.key});

  @override
  State<ReceiverDashboard> createState() => _ReceiverDashboardState();
}

class _ReceiverDashboardState extends State<ReceiverDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Food')),
      body: foodList.isEmpty
          ? const Center(child: Text('No food available'))
          : ListView.builder(
              itemCount: foodList.length,
              itemBuilder: (context, index) {
                final food = foodList[index];

                if (food.isExpired) {
                  food.status = 'Expired';
                }

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        Text('Quantity: ${food.plates} plates'),
                        Text('Location: ${food.location}'),
                        Text('Temperature: ${food.temperature} °C'),

                        const SizedBox(height: 6),

                        Text(
                          'Status: ${food.displayStatus}',
                          style: TextStyle(
                            color: food.statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (!food.isExpired)
                          Text(
                            'Time left: ${food.remainingTime.inHours}h '
                            '${food.remainingTime.inMinutes % 60}m',
                          ),

                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed:
                                food.status == 'Available' && !food.isExpired
                                ? () {
                                    setState(() {
                                      food.status = 'Requested';
                                    });
                                  }
                                : null,
                            child: const Text('Request Pickup'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
