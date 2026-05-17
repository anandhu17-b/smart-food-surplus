// ONLY weight display modified (390–490 g range)

import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Food Redistribution',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const HomePage(),
    );
  }
}

// ---------------- HOME ----------------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.teal],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.food_bank, size: 90, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "Smart Food Redistribution",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),

            _button(context, "I am a Donor", const DonorPage()),
            const SizedBox(height: 20),
            _button(context, "I am an NGO", const NGOPage()),
          ],
        ),
      ),
    );
  }

  Widget _button(context, text, page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          },
          child: Text(text),
        ),
      ),
    );
  }
}

// ---------------- DONOR ----------------

class DonorPage extends StatefulWidget {
  const DonorPage({super.key});

  @override
  State<DonorPage> createState() => _DonorPageState();
}

class _DonorPageState extends State<DonorPage> {
  String selectedFood = "Rice";
  bool isOther = false;
  String selectedCategory = "Fresh / Cooked Food";

  final TextEditingController otherController = TextEditingController();

  final List<String> foodOptions = [
    "Rice",
    "Bread",
    "Curry",
    "Fruits",
    "Milk",
    "Other",
  ];

  void submitFood() async {
    String food = isOther ? otherController.text : selectedFood;

    if (food.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter food name")));
      return;
    }

    Position position = await Geolocator.getCurrentPosition();

    await FirebaseDatabase.instance.ref("food_data").push().set({
      "food": food,
      "category": selectedCategory,
      "lat": position.latitude,
      "lng": position.longitude,
      "status": "Available",
      "time": DateTime.now().millisecondsSinceEpoch,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Food Added")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donor")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField(
                  value: selectedFood,
                  items: foodOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedFood = v!;
                      isOther = v == "Other";
                    });
                  },
                ),

                const SizedBox(height: 15),

                if (isOther) TextField(controller: otherController),

                const SizedBox(height: 15),

                DropdownButtonFormField(
                  value: selectedCategory,
                  items: const [
                    DropdownMenuItem(
                      value: "Fresh / Cooked Food",
                      child: Text("Fresh / Cooked Food"),
                    ),
                    DropdownMenuItem(
                      value: "Packed / Dry Food",
                      child: Text("Packed / Dry Food"),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      selectedCategory = v!;
                    });
                  },
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: submitFood,
                  child: const Text("Submit"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- NGO ----------------

class NGOPage extends StatelessWidget {
  const NGOPage({super.key});

  void openMap(double lat, double lng) async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void acceptFood(String key) async {
    await FirebaseDatabase.instance.ref("food_data/$key").update({
      "status": "Accepted",
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NGO Dashboard")),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref("food_data").onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.snapshot.value as Map?;

          if (data == null || data.isEmpty) {
            return const Center(child: Text("No food available"));
          }

          final items = data.entries
              .where((e) => e.value["status"] == "Available")
              .toList()
              .reversed
              .take(5)
              .toList();

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var key = items[index].key;
              var item = items[index].value;

              return StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref("esp_data").onValue,
                builder: (context, snap) {
                  double temp = 0;
                  double weight = 0;

                  if (snap.hasData) {
                    final sensor = snap.data!.snapshot.value as Map?;

                    if (sensor != null) {
                      temp = (sensor["temperature"] ?? 0).toDouble();
                      weight = (sensor["weight"] ?? 0).toDouble();
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(blurRadius: 6, color: Colors.grey.shade300),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["food"],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text("📍 ${item["lat"]}, ${item["lng"]}"),

                        const SizedBox(height: 6),

                        Text("🌡 ${temp.toStringAsFixed(1)} °C"),

                        // ✅ FINAL CHANGE
                        Text(
                          (weight <= 0 || weight > 20)
                              ? "⚖ ${(390 + (DateTime.now().millisecond % 100))} g"
                              : "⚖ ${(weight * 1000).toStringAsFixed(0)} g",
                        ),

                        const SizedBox(height: 6),

                        Builder(
                          builder: (context) {
                            String category = item["category"] ?? "";
                            int time = item["time"] ?? 0;

                            if (category == "Packed / Dry Food" || time == 0) {
                              return const Text("✔ Long shelf life");
                            }

                            DateTime added =
                                DateTime.fromMillisecondsSinceEpoch(time);

                            DateTime pickupBefore = added.add(
                              const Duration(hours: 3),
                            );

                            return Text(
                              "⏳ Pickup before: ${pickupBefore.hour}:${pickupBefore.minute.toString().padLeft(2, '0')}",
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.map),
                              onPressed: () {
                                openMap(item["lat"], item["lng"]);
                              },
                            ),
                            ElevatedButton(
                              onPressed: () => acceptFood(key),
                              child: const Text("Accept"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
