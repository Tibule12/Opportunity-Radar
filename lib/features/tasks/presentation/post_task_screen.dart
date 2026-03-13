import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/state_panels.dart';

class PostTaskScreen extends StatelessWidget {
  const PostTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Post Task',
      child: _PostTaskForm(),
    );
  }
}

class _PostTaskForm extends StatelessWidget {
  const _PostTaskForm();

  @override
  Widget build(BuildContext context) {
    return const _TaskFormView();
  }
}

class _TaskFormView extends ConsumerStatefulWidget {
  const _TaskFormView();

  @override
  ConsumerState<_TaskFormView> createState() => _TaskFormViewState();
}

class _TaskFormViewState extends ConsumerState<_TaskFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  String _selectedCategory = 'delivery';
  int _expiresInHours = 2;
  bool _isSubmitting = false;
  bool _isLocating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF13231F), Color(0xFF28536B)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Post in minutes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Describe the opportunity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Clear details, a strong budget, and precise location data will improve response speed and trusted-worker conversion.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _FormSectionCard(
            title: 'Core details',
            subtitle: 'Tell workers what needs to happen and why the job is worth their time.',
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(labelText: 'Task title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a task title.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isSubmitting,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a task description.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
                    DropdownMenuItem(value: 'transport', child: Text('Transport')),
                    DropdownMenuItem(value: 'errands', child: Text('Errands')),
                    DropdownMenuItem(value: 'moving_help', child: Text('Moving Help')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _budgetController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(labelText: 'Budget (ZAR)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid budget.';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _FormSectionCard(
            title: 'Location and timing',
            subtitle: 'Better location data improves trusted-worker and nearby-worker fan-out.',
            child: Column(
              children: [
                TextFormField(
                  controller: _locationController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a task location.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        enabled: !_isSubmitting,
                        decoration: const InputDecoration(labelText: 'Latitude'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (value) {
                          final latitudeText = (value ?? '').trim();
                          final longitudeText = _longitudeController.text.trim();
                          final latitude = latitudeText.isEmpty ? null : double.tryParse(latitudeText);
                          if ((latitudeText.isNotEmpty && latitude == null) ||
                              (latitudeText.isEmpty && longitudeText.isNotEmpty)) {
                            return 'Enter both coordinates';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        enabled: !_isSubmitting,
                        decoration: const InputDecoration(labelText: 'Longitude'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (value) {
                          final longitudeText = (value ?? '').trim();
                          final latitudeText = _latitudeController.text.trim();
                          final longitude = longitudeText.isEmpty ? null : double.tryParse(longitudeText);
                          if ((longitudeText.isNotEmpty && longitude == null) ||
                              (longitudeText.isEmpty && latitudeText.isNotEmpty)) {
                            return 'Enter both coordinates';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: (_isSubmitting || _isLocating) ? null : _fillCurrentLocation,
                  icon: const Icon(Icons.my_location_outlined),
                  label: Text(_isLocating ? 'Fetching location...' : 'Use current location'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _expiresInHours,
                  decoration: const InputDecoration(labelText: 'Expires in'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 hour')),
                    DropdownMenuItem(value: 2, child: Text('2 hours')),
                    DropdownMenuItem(value: 4, child: Text('4 hours')),
                    DropdownMenuItem(value: 8, child: Text('8 hours')),
                    DropdownMenuItem(value: 24, child: Text('24 hours')),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _expiresInHours = value;
                          });
                        },
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(_isSubmitting ? 'Publishing...' : 'Publish task to the market'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    if (currentUser == null) {
      setState(() {
        _errorMessage = 'You must be signed in to create a task.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final latitude = _latitudeController.text.trim().isEmpty
          ? null
          : double.parse(_latitudeController.text.trim());
      final longitude = _longitudeController.text.trim().isEmpty
          ? null
          : double.parse(_longitudeController.text.trim());

      await ref.read(taskRepositoryProvider).createTask(
            createdBy: currentUser.uid,
            title: _titleController.text,
            description: _descriptionController.text,
            category: _selectedCategory,
            budgetAmount: double.parse(_budgetController.text.trim()),
            locationAddress: _locationController.text,
            locationLat: latitude,
            locationLng: longitude,
            expiresIn: Duration(hours: _expiresInHours),
          );

      if (!mounted) {
        return;
      }

      showMarketplaceMessage(context, 'Task is live in the feed.');
      context.go('/feed');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Failed to publish task: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _fillCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _errorMessage = null;
    });

    try {
      final location = await ref.read(locationServiceProvider).getCurrentLocation();
      if (!mounted) {
        return;
      }

      setState(() {
        _latitudeController.text = location.latitude.toStringAsFixed(6);
        _longitudeController.text = location.longitude.toStringAsFixed(6);
        if ((location.addressText ?? '').trim().isNotEmpty) {
          _locationController.text = location.addressText!;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Failed to get current location: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }
}

class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(subtitle),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}
