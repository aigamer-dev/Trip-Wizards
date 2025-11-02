import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:travel_wizards/src/shared/services/places_api_service.dart';

/// A text field with Google Places API autocomplete functionality
class PlacesAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final Icon? prefixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<PlacePrediction>? onPlaceSelected;
  final bool enabled;
  final String? sessionToken;
  final PlacesApiService? apiService;

  /// Allows widget tests to supply a custom service without plumbing it through the
  /// entire app. Production code should leave this alone.
  static PlacesApiService? _testServiceOverride;

  /// Set a global override for the Places API service in tests.
  /// Pass null to restore the default singleton.
  static void overrideDefaultServiceForTesting(PlacesApiService? service) {
    _testServiceOverride = service;
  }

  const PlacesAutocompleteField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText = '',
    this.prefixIcon,
    this.onChanged,
    this.onPlaceSelected,
    this.enabled = true,
    this.sessionToken,
    this.apiService,
  });

  @override
  State<PlacesAutocompleteField> createState() =>
      _PlacesAutocompleteFieldState();
}

class _PlacesAutocompleteFieldState extends State<PlacesAutocompleteField> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  List<PlacePrediction> _predictions = [];
  bool _isSearching = false;
  String _sessionToken = '';
  late PlacesApiService _service;

  @override
  void initState() {
    super.initState();
    _sessionToken =
        widget.sessionToken ?? DateTime.now().millisecondsSinceEpoch.toString();
    _service =
        widget.apiService ??
        PlacesAutocompleteField._testServiceOverride ??
        PlacesApiService.instance;
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
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
    final text = widget.controller.text;
    widget.onChanged?.call(text);

    if (text.isEmpty) {
      _removeOverlay();
      return;
    }

    if (_focusNode.hasFocus) {
      _searchPlaces(text);
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 2) {
      _removeOverlay();
      return;
    }

    setState(() => _isSearching = true);

    try {
      final predictions = await _service.searchLocations(
        query,
        sessionToken: _sessionToken,
      );

      if (mounted && _focusNode.hasFocus) {
        setState(() {
          _predictions = predictions;
          _isSearching = false;
        });
        _showOverlay();
      }
    } catch (e) {
      debugPrint('❌ Error searching places: $e');
      setState(() => _isSearching = false);
    }
  }

  void _showOverlay() {
    _removeOverlay();

    if (_predictions.isEmpty && !_isSearching) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: offset.dx,
          top: offset.dy + size.height + 4,
          width: size.width,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Semantics(
                container: true,
                liveRegion: true,
                label: _isSearching
                    ? 'Searching for places'
                    : 'Place suggestions',
                child: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Searching...'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _predictions.length,
                        itemBuilder: (context, index) {
                          final prediction = _predictions[index];
                          final semanticsLabel =
                              prediction.secondaryText.trim().isEmpty
                              ? prediction.mainText
                              : '${prediction.mainText}, ${prediction.secondaryText}';
                          return Semantics(
                            button: true,
                            label: semanticsLabel,
                            hint: 'Select place suggestion',
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.location_on,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              title: Text(
                                prediction.mainText,
                                semanticsLabel: semanticsLabel,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                prediction.secondaryText,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              onTap: () => _selectPlace(prediction),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectPlace(PlacePrediction prediction) {
    widget.controller.text = prediction.description;
    widget.onPlaceSelected?.call(prediction);
    _announceSelection(prediction);
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _announceSelection(PlacePrediction prediction) {
    final directionality = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final location = prediction.secondaryText.trim().isEmpty
        ? prediction.mainText
        : '${prediction.mainText}, ${prediction.secondaryText}';
    SemanticsService.announce('$location selected', directionality);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
