import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  String _relationship = "Dad";
  int _delaySeconds = 0;
  String _ringtone = "Default";

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // Load saved user settings
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    _nameController.text = prefs.getString('fakeCallerName') ?? "Dad";
    _numberController.text = prefs.getString('fakeCallerNumber') ?? "";
    _relationship = prefs.getString('fakeCallerRelation') ?? "Dad";
    _delaySeconds = prefs.getInt('fakeCallDelay') ?? 0;
    _ringtone = prefs.getString('fakeCallRingtone') ?? "Default";

    setState(() => _isLoading = false);
  }

  // Save and trigger fake call
  Future<void> _saveSettings() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a caller name")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('fakeCallerName', _nameController.text.trim());
    await prefs.setString('fakeCallerNumber', _numberController.text.trim());
    await prefs.setString('fakeCallerRelation', _relationship);
    await prefs.setInt('fakeCallDelay', _delaySeconds);
    await prefs.setString('fakeCallRingtone', _ringtone);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fake caller saved 💜")),
    );
Navigator.pop(context);

    
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Fake Caller Setup",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF3ECFF),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Who should call you?",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  // Caller name
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Caller Name",
                      hintText: "e.g. Dad, Police Control Room",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Caller number
                  TextField(
                    controller: _numberController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Caller Number (optional)",
                      hintText: "+91 98XXXXXXX",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Relationship
                  const Text(
                    "Relationship",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _relationship,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Dad", child: Text("Dad")),
                      DropdownMenuItem(value: "Mom", child: Text("Mom")),
                      DropdownMenuItem(value: "Friend", child: Text("Friend")),
                      DropdownMenuItem(
                          value: "Police", child: Text("Police Control Room")),
                      DropdownMenuItem(value: "Custom", child: Text("Custom")),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _relationship = val);
                    },
                  ),
                  const SizedBox(height: 18),

                  // Delay chips
                  const Text(
                    "Ring delay",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _delayChip(0, "Instant"),
                      _delayChip(5, "5s"),
                      _delayChip(10, "10s"),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Ringtone dropdown
                  const Text(
                    "Ringtone",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _ringtone,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: "Default", child: Text("Default")),
                      DropdownMenuItem(
                          value: "Police", child: Text("Police tone")),
                      DropdownMenuItem(
                          value: "Soft", child: Text("Soft ring")),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _ringtone = val);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Save Fake Caller",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Delay chips widget
  Widget _delayChip(int value, String label) {
    final bool selected = _delaySeconds == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _delaySeconds = value),
      selectedColor: const Color(0xFF8B5CF6),
      labelStyle:
          TextStyle(color: selected ? Colors.white : Colors.black87),
      backgroundColor: Colors.white.withOpacity(0.7),
    );
  }
}

