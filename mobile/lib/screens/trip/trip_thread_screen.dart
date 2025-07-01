import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripthread/providers/trip_provider.dart';
import 'package:tripthread/providers/auth_provider.dart';
import 'package:tripthread/models/trip.dart';
import 'package:tripthread/widgets/custom_text_field.dart';

class TripThreadScreen extends StatefulWidget {
  final String tripId;

  const TripThreadScreen({
    Key? key,
    required this.tripId,
  }) : super(key: key);

  @override
  State<TripThreadScreen> createState() => _TripThreadScreenState();
}

class _TripThreadScreenState extends State<TripThreadScreen> {
  final _textController = TextEditingController();
  final _locationController = TextEditingController();
  final _scrollController = ScrollController();
  
  Trip? _trip;
  bool _isLoading = true;
  ThreadEntryType _selectedType = ThreadEntryType.text;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  @override
  void dispose() {
    _textController.dispose();
    _locationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTrip() async {
    final tripProvider = context.read<TripProvider>();
    final trip = await tripProvider.getTrip(widget.tripId);
    
    if (mounted) {
      setState(() {
        _trip = trip;
        _isLoading = false;
      });
      
      if (trip != null) {
        await tripProvider.loadCurrentTripEntries();
      }
    }
  }

  Future<void> _addEntry() async {
    final tripProvider = context.read<TripProvider>();
    bool success = false;

    switch (_selectedType) {
      case ThreadEntryType.text:
        if (_textController.text.trim().isNotEmpty) {
          success = await tripProvider.addTextEntry(_textController.text.trim());
          if (success) _textController.clear();
        }
        break;
      case ThreadEntryType.location:
        if (_locationController.text.trim().isNotEmpty) {
          success = await tripProvider.addLocationEntry(
            _locationController.text.trim(),
            notes: _textController.text.trim().isEmpty ? null : _textController.text.trim(),
          );
          if (success) {
            _locationController.clear();
            _textController.clear();
          }
        }
        break;
      case ThreadEntryType.media:
        // TODO: Implement media picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media upload coming soon!')),
        );
        break;
      case ThreadEntryType.checkin:
        // TODO: Implement check-in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in feature coming soon!')),
        );
        break;
    }

    if (success) {
      // Scroll to bottom to show new entry
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Thread')),
        body: const Center(
          child: Text('Trip not found'),
        ),
      );
    }

    final currentUser = context.read<AuthProvider>().currentUser;
    final canAddEntries = currentUser?.id == _trip!.userId && _trip!.status == TripStatus.ongoing;

    return Scaffold(
      appBar: AppBar(
        title: Text(_trip!.title),
        // subtitle: Text('Trip Thread'),
      ),
      body: Column(
        children: [
          // Thread entries
          Expanded(
            child: Consumer<TripProvider>(
              builder: (context, tripProvider, child) {
                final entries = tripProvider.currentTripEntries;
                
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No entries yet',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          canAddEntries 
                              ? 'Start documenting your journey!'
                              : 'This trip has no entries yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    return _buildThreadEntry(entries[index]);
                  },
                );
              },
            ),
          ),
          
          // Add entry section
          if (canAddEntries) _buildAddEntrySection(),
        ],
      ),
    );
  }

  Widget _buildThreadEntry(TripThreadEntry entry) {
    final isCurrentUser = context.read<AuthProvider>().currentUser?.id == entry.authorId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage: entry.author.avatarUrl != null 
                ? NetworkImage(entry.author.avatarUrl!) 
                : null,
            child: entry.author.avatarUrl == null 
                ? Text(
                    entry.author.name?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          
          const SizedBox(width: 12),
          
          // Entry content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        entry.author.name ?? 'User',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildEntryTypeIcon(entry.type),
                      const Spacer(),
                      Text(
                        _formatDateTime(entry.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Content
                  if (entry.contentText != null) ...[
                    Text(
                      entry.contentText!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Location
                  if (entry.locationName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.locationName!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Media placeholder
                  if (entry.type == ThreadEntryType.media && entry.mediaUrl != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
                    ),
                  
                  // Tagged users
                  if (entry.taggedUsers != null && entry.taggedUsers!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 4,
                        children: entry.taggedUsers!.map((user) {
                          return Chip(
                            label: Text(
                              '@${user.username ?? user.name ?? 'User'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddEntrySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Entry type selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ThreadEntryType.values.map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildEntryTypeIcon(type),
                        const SizedBox(width: 4),
                        Text(_getEntryTypeLabel(type)),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = type;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Input fields based on type
          if (_selectedType == ThreadEntryType.location) ...[
            CustomTextField(
              controller: _locationController,
              label: 'Location',
              hintText: 'Where are you?',
              prefixIcon: Icons.location_on,
            ),
            const SizedBox(height: 8),
          ],
          
          // Text input (always shown for notes/captions)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: _getInputHint(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              Consumer<TripProvider>(
                builder: (context, tripProvider, child) {
                  return IconButton(
                    onPressed: tripProvider.isLoading ? null : _addEntry,
                    icon: tripProvider.isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  );
                },
              ),
            ],
          ),
          
          // Error message
          Consumer<TripProvider>(
            builder: (context, tripProvider, child) {
              if (tripProvider.error != null) {
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tripProvider.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTypeIcon(ThreadEntryType type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case ThreadEntryType.text:
        icon = Icons.text_fields;
        color = Colors.blue;
        break;
      case ThreadEntryType.media:
        icon = Icons.photo_camera;
        color = Colors.green;
        break;
      case ThreadEntryType.location:
        icon = Icons.location_on;
        color = Colors.red;
        break;
      case ThreadEntryType.checkin:
        icon = Icons.check_circle;
        color = Colors.orange;
        break;
    }
    
    return Icon(icon, color: color, size: 16);
  }

  String _getEntryTypeLabel(ThreadEntryType type) {
    switch (type) {
      case ThreadEntryType.text:
        return 'Text';
      case ThreadEntryType.media:
        return 'Media';
      case ThreadEntryType.location:
        return 'Location';
      case ThreadEntryType.checkin:
        return 'Check-in';
    }
  }

  String _getInputHint() {
    switch (_selectedType) {
      case ThreadEntryType.text:
        return 'Share your thoughts...';
      case ThreadEntryType.media:
        return 'Add a caption...';
      case ThreadEntryType.location:
        return 'Add notes about this place...';
      case ThreadEntryType.checkin:
        return 'How was your experience?';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}