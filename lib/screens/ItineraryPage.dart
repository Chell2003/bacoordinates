import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItineraryPage extends StatefulWidget {
  final String placeId;

  const ItineraryPage({super.key, required this.placeId});

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Itinerary')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItineraryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Itinerary'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .collection('itineraries')
            .orderBy('date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: snapshot.data!.docs.map((doc) {
              var itinerary = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(itinerary['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${itinerary['description']}\nDate: ${itinerary['date']}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteItinerary(doc.id),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_note, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No itineraries added yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _generateSampleItinerary,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Sample Itinerary'),
          ),
        ],
      ),
    );
  }

  void _showAddItineraryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Itinerary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(_selectedDate == null ? 'Select Date' : 'Date: ${_selectedDate!.toLocal()}'.split(' ')[0]),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDate,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: _addItinerary, child: const Text('Save')),
          ],
        );
      },
    );
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _addItinerary() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _selectedDate == null) {
      return;
    }

    FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .collection('itineraries')
        .add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'date': _selectedDate!.toIso8601String(),
    });

    _titleController.clear();
    _descriptionController.clear();
    _selectedDate = null;
    Navigator.pop(context);
  }

  void _deleteItinerary(String docId) {
    FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .collection('itineraries')
        .doc(docId)
        .delete();
  }

  void _generateSampleItinerary() {
    FirebaseFirestore.instance.collection('places').doc(widget.placeId).collection('itineraries').add({
      'title': 'City Tour',
      'description': 'Explore the historical landmarks and famous streets.',
      'date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    });

    FirebaseFirestore.instance.collection('places').doc(widget.placeId).collection('itineraries').add({
      'title': 'Beach Day',
      'description': 'Relax at the beach and enjoy the sunset.',
      'date': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
    });
  }
}
