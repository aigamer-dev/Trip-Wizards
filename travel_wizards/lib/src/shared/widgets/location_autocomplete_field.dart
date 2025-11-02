import 'dart:async';
import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/services/indian_location_service.dart';
import 'package:travel_wizards/src/shared/services/nominatim_service.dart';

/// A prediction item compatible with both Nominatim and legacy code
class LocationAutocompleteResult {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final double? latitude;
  final double? longitude;

  LocationAutocompleteResult({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.latitude,
    this.longitude,
  });

  factory LocationAutocompleteResult.fromNominatim(LocationPrediction pred) {
    return LocationAutocompleteResult(
      placeId: pred.placeId,
      description: pred.description,
      mainText: pred.mainText,
      secondaryText: pred.secondaryText,
      latitude: pred.latitude,
      longitude: pred.longitude,
    );
  }
}

/// A text field with FREE location autocomplete using OpenStreetMap Nominatim
/// NO API KEY REQUIRED - Completely free to use
class LocationAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final Icon? prefixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<LocationAutocompleteResult>? onPlaceSelected;
  final bool enabled;

  const LocationAutocompleteField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText = '',
    this.prefixIcon,
    this.onChanged,
    this.onPlaceSelected,
    this.enabled = true,
  });

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  List<LocationAutocompleteResult> _predictions = [];
  bool _isSearching = false;
  final IndianLocationService _service = IndianLocationService.instance;

  // Add debouncing and cancellation
  Timer? _debounceTimer;
  String? _currentSearchQuery;
  bool _isSelecting = false; // Prevent search during selection

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && widget.controller.text.isNotEmpty) {
      _searchPlaces(widget.controller.text);
    } else {
      _removeOverlay();
    }
  }

  void _onTextChanged() {
    if (_isSelecting) return; // Ignore text changes during selection

    final text = widget.controller.text;
    widget.onChanged?.call(text);

    // Cancel previous timer
    _debounceTimer?.cancel();

    if (text.isEmpty) {
      _removeOverlay();
      return;
    }

    if (_focusNode.hasFocus) {
      // Debounce the search by 300ms
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (_currentSearchQuery != text) {
          _currentSearchQuery = text;
          _searchPlaces(text);
        }
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 2) {
      _removeOverlay();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Use the enhanced Indian location service - FREE and optimized for India!
      final results = await _service.searchIndianLocations(query, limit: 8);

      // Check if this is still the current query (avoid race conditions)
      if (_currentSearchQuery == query && mounted) {
        setState(() {
          _predictions = results
              .map((pred) => LocationAutocompleteResult.fromNominatim(pred))
              .toList();
          _isSearching = false;
        });

        if (_predictions.isNotEmpty && _focusNode.hasFocus) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    } catch (e) {
      debugPrint('❌ Error searching locations: $e');
      if (_currentSearchQuery == query && mounted) {
        setState(() {
          _predictions = [];
          _isSearching = false;
        });
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();

    if (_predictions.isEmpty && !_isSearching) {
      return;
    }

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _predictions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No locations found',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _predictions.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    itemBuilder: (context, index) {
                      final prediction = _predictions[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        title: Text(
                          prediction.mainText,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: prediction.secondaryText.isNotEmpty
                            ? Text(
                                prediction.secondaryText,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () => _selectPlace(prediction),
                      );
                    },
                  ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectPlace(LocationAutocompleteResult prediction) {
    _isSelecting = true; // Prevent text change handling
    _debounceTimer?.cancel(); // Cancel any pending searches

    widget.controller.text = prediction.description;
    widget.onPlaceSelected?.call(prediction);
    _removeOverlay();
    _focusNode.unfocus();

    // Reset selection flag after a brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _isSelecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.labelText,
      hint: 'Autocomplete field for ${widget.labelText}',
      textField: true,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.controller.clear();
                    _removeOverlay();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
