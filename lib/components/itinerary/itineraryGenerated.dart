import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItineraryGenerated extends StatefulWidget {
  final String placeId;
  final String placeTitle;
  final String placeDescription;

  const ItineraryGenerated({
    super.key,
    required this.placeId,
    required this.placeTitle,
    required this.placeDescription,
  });

  @override
  State<ItineraryGenerated> createState() => _ItineraryGeneratedState();
}

class _ItineraryGeneratedState extends State<ItineraryGenerated> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  int _duration = 1;
  List<String> _selectedActivities = [];
  bool _isLoading = false;

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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Generate Custom Itinerary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Itinerary Title',
                        hintText: 'e.g., Weekend Getaway',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Duration & Date',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text('Duration: '),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButton<int>(
                                    value: _duration,
                                    underline: const SizedBox(),
                                    items: List.generate(7, (index) => index + 1).map((int value) {
                                      return DropdownMenuItem<int>(
                                        value: value,
                                        child: Text('$value days'),
                                      );
                                    }).toList(),
                                    onChanged: (int? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _duration = newValue;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: _pickDate,
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(_selectedDate == null 
                                    ? 'Select Date' 
                                    : 'Start: ${_selectedDate!.toLocal()}'.split(' ')[0]),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Activities',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _availableActivities.map((activity) {
                                return FilterChip(
                                  label: Text(activity),
                                  selected: _selectedActivities.contains(activity),
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedActivities.add(activity);
                                      } else {
                                        _selectedActivities.remove(activity);
                                      }
                                    });
                                  },
                                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                  checkmarkColor: Theme.of(context).primaryColor,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _generateItinerary,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate Itinerary'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Future<void> _generateItinerary() async {
    if (_titleController.text.isEmpty || _selectedDate == null || _selectedActivities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Generate activities for each day
      for (int day = 0; day < _duration; day++) {
        final currentDate = _selectedDate!.add(Duration(days: day));
        final activities = _generateDayActivities(day + 1);
        
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .collection('itineraries')
            .add({
          'title': '${_titleController.text} - Day ${day + 1}',
          'description': activities,
          'date': currentDate.toIso8601String(),
          'activities': _selectedActivities,
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itinerary generated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating itinerary: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _generateDayActivities(int day) {
    final activities = <String>[];
    
    if (_selectedActivities.contains('Morning Tour')) {
      activities.add('9:00 AM - Start your day with a guided tour of ${widget.placeTitle}');
    }
    
    if (_selectedActivities.contains('Afternoon Exploration')) {
      activities.add('1:00 PM - Explore local attractions and hidden gems');
    }
    
    if (_selectedActivities.contains('Evening Activities')) {
      activities.add('6:00 PM - Enjoy evening entertainment and local nightlife');
    }
    
    if (_selectedActivities.contains('Local Food Experience')) {
      activities.add('12:00 PM - Savor local cuisine at recommended restaurants');
    }
    
    if (_selectedActivities.contains('Cultural Activities')) {
      activities.add('3:00 PM - Immerse yourself in local culture and traditions');
    }
    
    if (_selectedActivities.contains('Shopping')) {
      activities.add('4:00 PM - Browse local markets and shops');
    }
    
    if (_selectedActivities.contains('Relaxation')) {
      activities.add('2:00 PM - Take a break and relax at scenic spots');
    }
    
    if (_selectedActivities.contains('Adventure Activities')) {
      activities.add('10:00 AM - Experience thrilling adventure activities');
    }

    return activities.join('\n');
  }
}
