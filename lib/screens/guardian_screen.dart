
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// -------------------------------------------------------
/// GUARDIAN MODEL
/// -------------------------------------------------------
class Guardian {
  final String id;
  final String name;
  final String phone;
  final String email;


  Guardian({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
  });

  Map<String, dynamic> toMap(String userId) {
    return {
      'userId': userId,
      'Name': name,
      'Phone': phone,
       'Email': email,
      'CreatedAt': DateTime.now(),
    };
  }

  factory Guardian.fromMap(String id, Map<String, dynamic> map) {
    return Guardian(
      id: id,
      name: map['Name'] ?? '',
      phone: map['Phone'] ?? '',
       email: map['Email'] ?? '',
    );
  }
}

/// -------------------------------------------------------
/// GUARDIAN SCREEN (MAIN UI)
/// -------------------------------------------------------
class GuardianScreen extends StatefulWidget {
  const GuardianScreen({super.key});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();


  final int maxGuardians = 5;

  void openGuardianDialog({Guardian? guardian}) {
    if (guardian != null) {
      nameController.text = guardian.name;
      phoneController.text = guardian.phone;
    } else {
      nameController.clear();
      phoneController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(guardian == null ? "Add Guardian" : "Edit Guardian"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Guardian Name"),
              ),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Phone Number"),
              ),
              TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Email Address"),
            ),

            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty ||
                    phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                  return;
                }

                if (guardian == null) {
                  addGuardian();
                } else {
                  updateGuardian(guardian.id);
                }

                Navigator.pop(context);
              },
              child: Text(guardian == null ? "Add" : "Update"),
            ),
          ],
        );
      },
    );
  }
Future<void> addGuardian() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // limit check (keep your logic)
  final snapshot = await FirebaseFirestore.instance
      .collection('guardians')
      .where('userId', isEqualTo: user.uid)
      .get();

  if (snapshot.docs.length >= maxGuardians) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Maximum $maxGuardians guardians allowed")),
    );
    return;
  }

  final email = emailController.text.trim().toLowerCase();

  // 1️⃣ Save guardian basic info (existing behavior)
  final guardian = Guardian(
    id: "",
    name: nameController.text.trim(),
    phone: phoneController.text.trim(),
    email: email,
  );

  await FirebaseFirestore.instance
      .collection('guardians')
      .add(guardian.toMap(user.uid));

  // 2️⃣ CREATE GUARDIAN INVITE (NEW, IMPORTANT)
  await FirebaseFirestore.instance.collection('guardian_invites').add({
    'email': email,
    'userId': user.uid,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });
}

  

  Future<void> updateGuardian(String id) async {
    await FirebaseFirestore.instance.collection('guardians').doc(id).update({
      'Name': nameController.text.trim(),
      'Phone': phoneController.text.trim(),
      'Email': emailController.text.trim(),
    });
  }

  Future<void> deleteGuardian(String id) async {
    await FirebaseFirestore.instance.collection('guardians').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Guardian Mode"),
        backgroundColor: Colors.deepPurple,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => openGuardianDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: user == null
            ? const Stream.empty()
            : FirebaseFirestore.instance
                .collection('guardians')
                .where('userId', isEqualTo: user.uid)
                // 🔴 removed orderBy('CreatedAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // show actual error to help debug later
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No guardians added yet",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final guardian = Guardian.fromMap(
                docs[index].id,
                docs[index].data() as Map<String, dynamic>,
              );

              return Dismissible(
                key: Key(guardian.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => deleteGuardian(guardian.id),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(guardian.name),
                    subtitle: Text(guardian.phone),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.deepPurple),
                      onPressed: () => openGuardianDialog(guardian: guardian),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
