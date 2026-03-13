import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/models/user_profile.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _locationAddressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  bool _isCustomer = true;
  bool _isWorker = true;
  String _availabilityStatus = 'offline';
  bool _isSaving = false;
  bool _isLocating = false;
  String? _errorMessage;
  bool _didLoadProfile = false;

  @override
  void dispose() {
    _nameController.dispose();
    _referralCodeController.dispose();
    _locationAddressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile = profileAsync.valueOrNull;
    _hydrate(profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Complete profile')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set up your account',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This profile is stored in Firestore and used to match you with nearby opportunities or help requests.',
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(labelText: 'Full name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _referralCodeController,
                        enabled: !_isSaving,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Referral code (optional)',
                          hintText: 'Enter a worker invite code',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _locationAddressController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Home area or base location',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _latitudeController,
                              enabled: !_isSaving,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: const InputDecoration(labelText: 'Latitude'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _longitudeController,
                              enabled: !_isSaving,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: const InputDecoration(labelText: 'Longitude'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: (_isSaving || _isLocating) ? null : _fillCurrentLocation,
                        icon: const Icon(Icons.my_location_outlined),
                        label: Text(_isLocating ? 'Fetching location...' : 'Use current location'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'How will you use the app?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('I want to post tasks as a customer'),
                        value: _isCustomer,
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  _isCustomer = value ?? false;
                                });
                              },
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('I want to receive tasks as a worker'),
                        value: _isWorker,
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  _isWorker = value ?? false;
                                });
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _availabilityStatus,
                        decoration: const InputDecoration(labelText: 'Worker mode'),
                        items: const [
                          DropdownMenuItem(value: 'online', child: Text('Online')),
                          DropdownMenuItem(value: 'busy', child: Text('Busy')),
                          DropdownMenuItem(value: 'offline', child: Text('Offline')),
                        ],
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _availabilityStatus = value;
                                });
                              },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Workers start offline until they explicitly choose Go Online on the dashboard.',
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        child: const Text('Save profile'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _hydrate(UserProfile? profile) {
    if (_didLoadProfile || profile == null) {
      return;
    }

    _nameController.text = profile.displayName;
    _locationAddressController.text = profile.locationAddress;
    if (profile.locationLat != null) {
      _latitudeController.text = profile.locationLat!.toString();
    }
    if (profile.locationLng != null) {
      _longitudeController.text = profile.locationLng!.toString();
    }
    _isCustomer = profile.roles.contains('customer');
    _isWorker = profile.roles.contains('worker');
    _availabilityStatus = profile.availabilityStatus;
    _didLoadProfile = true;
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        context.go('/');
      }
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Enter your name before continuing.';
      });
      return;
    }

    final latitudeText = _latitudeController.text.trim();
    final longitudeText = _longitudeController.text.trim();
    final latitude = latitudeText.isEmpty ? null : double.tryParse(latitudeText);
    final longitude = longitudeText.isEmpty ? null : double.tryParse(longitudeText);
    final hasOneCoordinate = (latitude == null) != (longitude == null);

    if (hasOneCoordinate || (latitudeText.isNotEmpty && latitude == null) || (longitudeText.isNotEmpty && longitude == null)) {
      setState(() {
        _errorMessage = 'Enter both latitude and longitude, or leave both blank.';
      });
      return;
    }

    final roles = <String>[
      if (_isCustomer) 'customer',
      if (_isWorker) 'worker',
    ];

    if (roles.isEmpty) {
      setState(() {
        _errorMessage = 'Select at least one role.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(userProfileRepositoryProvider).upsertProfile(
            uid: user.uid,
            displayName: _nameController.text,
            phoneNumber: user.phoneNumber ?? '',
            roles: roles,
            availabilityStatus: _availabilityStatus,
            locationAddress: _locationAddressController.text,
            locationLat: latitude,
            locationLng: longitude,
            referralCodeInput: _referralCodeController.text,
          );

      if (!mounted) {
        return;
      }

      context.go('/feed');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
          _locationAddressController.text = location.addressText!;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '$error';
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
