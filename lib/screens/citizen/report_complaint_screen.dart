import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/image_service.dart';
import '../../services/location_service.dart';
import '../../widgets/loading_button.dart';

class ReportComplaintScreen extends StatefulWidget {
  const ReportComplaintScreen({super.key});

  @override
  State<ReportComplaintScreen> createState() => _ReportComplaintScreenState();
}

class _ReportComplaintScreenState extends State<ReportComplaintScreen> {
  final _descController = TextEditingController();
  File? _image;
  double? _lat, _lng;
  String? _address;
  bool _fetchingLocation = false;
  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImageService.pickImage(context);
    if (file != null) setState(() => _image = file);
  }

  Future<void> _fetchLocation() async {
    setState(() => _fetchingLocation = true);
    final result = await LocationService.getCurrentLocation();
    if (result.success) {
      final address = await LocationService.reverseGeocode(
          result.latitude!, result.longitude!);
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
        _address = address;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.error!),
          backgroundColor: Colors.red,
        ));
      }
    }
    setState(() => _fetchingLocation = false);
  }

  Future<void> _submit() async {
    if (_descController.text.trim().isEmpty) {
      _snack('Please enter a description', isError: true); return;
    }
    if (_image == null) {
      _snack('Please attach a photo', isError: true); return;
    }
    if (_lat == null) {
      _snack('Please fetch your GPS location', isError: true); return;
    }

    // Use resolved address if available, fallback to lat/lng string
    final locationStr = _address ?? LocationService.format(_lat!, _lng!);

    setState(() => _submitting = true);
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      await ApiService.submitComplaint(
        description: _descController.text.trim(),
        location: locationStr,
        token: token,
      );
      if (mounted) {
        _snack('Complaint submitted successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Report Complaint'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Tap to add photo',
                              style: TextStyle(color: Colors.grey[500])),
                          const SizedBox(height: 4),
                          Text('Camera or Gallery',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12)),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_image!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8, right: 8,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.edit,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.description_outlined),
                ),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // GPS row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on,
                      color: _lat != null ? Colors.green : Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _fetchingLocation
                        ? const Text('Fetching location...',
                            style: TextStyle(color: Colors.grey))
                        : Text(
                            _lat != null
                                ? (_address ?? LocationService.format(_lat!, _lng!))
                                : 'Location not fetched',
                            style: TextStyle(
                              color: _lat != null
                                  ? Colors.black87
                                  : Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                  ),
                  if (_fetchingLocation)
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    TextButton(
                      onPressed: _fetchLocation,
                      child: Text(
                        _lat != null ? 'Refresh' : 'Fetch GPS',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            LoadingButton(
              isLoading: _submitting,
              label: 'Submit Complaint',
              color: Colors.green,
              icon: Icons.send,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
