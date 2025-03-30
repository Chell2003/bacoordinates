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
  final TextEditingController _activityController = TextEditingController();
  DateTime? _selectedDate;
  List<String> _activities = [];


  final List<String> _availableActivities = [
    'Morning Tour',
    'Afternoon Exploration',
    'Evening Activities',
    'Local Food Experience',
    'Cultural Activities',
    'Shopping',
    'Relaxation',
    'Adventure Activities',
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinerary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddItineraryDialog,
          ),
        ],
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


          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var itinerary = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  title: Text(
                    itinerary['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Date: ${itinerary['date'].split('T')[0]}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Activities:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showAddActivityDialog(doc.id),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Activity'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (itinerary['activities'] != null) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (itinerary['activities'] as List<dynamic>)
                                  .map((activity) => Chip(
                                label: Text(
                                  activity,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                                onDeleted: () => _deleteActivity(doc.id, activity),
                              ))
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                          const Text(
                            'Schedule:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            itinerary['description'],
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ButtonBar(
                      children: [
                        TextButton.icon(
                          onPressed: () => _deleteItinerary(doc.id),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
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
          Icon(
            Icons.event_note,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No itineraries added yet.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _generateSampleItinerary,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Sample Itinerary'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showAddItineraryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Itinerary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : 'Date: ${_selectedDate!.toLocal()}'.split(' ')[0],
                      style: TextStyle(
                        color: _selectedDate == null ? Colors.grey : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addItinerary,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
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


  void _showAddActivityDialog(String itineraryId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _activityController,
                decoration: InputDecoration(
                  labelText: 'Activity Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.event),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Or select from common activities:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableActivities.map((activity) {
                  return ActionChip(
                    label: Text(activity),
                    onPressed: () {
                      _activityController.text = activity;
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_activityController.text.isNotEmpty) {
                        _addActivity(itineraryId);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _addActivity(String itineraryId) async {
    final docRef = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .collection('itineraries')
        .doc(itineraryId);


    final doc = await docRef.get();
    final data = doc.data() as Map<String, dynamic>;
    final activities = List<String>.from(data['activities'] ?? []);


    if (!activities.contains(_activityController.text)) {
      activities.add(_activityController.text);
      await docRef.update({'activities': activities});
    }


    _activityController.clear();
  }


  Future<void> _deleteActivity(String itineraryId, String activity) async {
    final docRef = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .collection('itineraries')
        .doc(itineraryId);


    final doc = await docRef.get();
    final data = doc.data() as Map<String, dynamic>;
    final activities = List<String>.from(data['activities'] ?? []);


    activities.remove(activity);
    await docRef.update({'activities': activities});
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





