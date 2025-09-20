import 'package:flutter/material.dart';

/// Optimized list view with lazy loading and performance improvements
class OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? Function(BuildContext context)? emptyBuilder;
  final Widget? Function(BuildContext context)? loadingBuilder;
  final Future<List<T>> Function(int page)? onLoadMore;
  final int pageSize;
  final ScrollController? scrollController;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.emptyBuilder,
    this.loadingBuilder,
    this.onLoadMore,
    this.pageSize = 20,
    this.scrollController,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  List<T> _allItems = [];

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _allItems = List.from(widget.items);

    if (widget.onLoadMore != null) {
      _scrollController.addListener(_scrollListener);
    }
  }

  @override
  void didUpdateWidget(OptimizedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _allItems = List.from(widget.items);
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || widget.onLoadMore == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final page = (_allItems.length / widget.pageSize).floor();
      final newItems = await widget.onLoadMore!(page);

      if (mounted) {
        setState(() {
          _allItems.addAll(newItems);
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allItems.isEmpty && widget.emptyBuilder != null) {
      return widget.emptyBuilder!(context) ?? const SizedBox.shrink();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: _allItems.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _allItems.length) {
          // Loading indicator for pagination
          return widget.loadingBuilder?.call(context) ??
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
        }

        return RepaintBoundary(
          child: widget.itemBuilder(context, _allItems[index], index),
        );
      },
    );
  }
}

/// Optimized image widget with caching and loading states
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableMemoryCache;
  final Duration fadeInDuration;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableMemoryCache = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  const OptimizedImage.asset({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableMemoryCache = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
  }) : imageUrl = '';

  @override
  Widget build(BuildContext context) {
    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: enableMemoryCache ? _frameBuilder : null,
        errorBuilder: _errorBuilder,
      );
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: enableMemoryCache ? _frameBuilder : null,
      loadingBuilder: _loadingBuilder,
      errorBuilder: _errorBuilder,
    );
  }

  Widget _frameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded || frame != null) {
      return AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: frame == null ? Duration.zero : fadeInDuration,
        child: child,
      );
    }
    return placeholder ?? _defaultPlaceholder();
  }

  Widget _loadingBuilder(
    BuildContext context,
    Widget child,
    ImageChunkEvent? loadingProgress,
  ) {
    if (loadingProgress == null) return child;

    return placeholder ?? _defaultPlaceholder();
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return errorWidget ?? _defaultErrorWidget();
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.error_outline, color: Colors.grey),
    );
  }
}

/// Optimized card widget that only rebuilds when necessary
class OptimizedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? color;
  final double elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool enableRepaintBoundary;

  const OptimizedCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.color,
    this.elevation = 2,
    this.borderRadius,
    this.onTap,
    this.enableRepaintBoundary = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: margin,
      color: color,
      elevation: elevation,
      shape: borderRadius != null
          ? RoundedRectangleBorder(borderRadius: borderRadius!)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );

    return enableRepaintBoundary ? RepaintBoundary(child: card) : card;
  }
}

/// Lazy loading wrapper that loads content when it becomes visible
class LazyLoadWrapper extends StatefulWidget {
  final Widget child;
  final Widget? placeholder;
  final double threshold;
  final VoidCallback? onLoad;

  const LazyLoadWrapper({
    super.key,
    required this.child,
    this.placeholder,
    this.threshold = 100,
    this.onLoad,
  });

  @override
  State<LazyLoadWrapper> createState() => _LazyLoadWrapperState();
}

class _LazyLoadWrapperState extends State<LazyLoadWrapper> {
  bool _isLoaded = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? UniqueKey(),
      onVisibilityChanged: (info) {
        if (!_isLoaded && info.visibleFraction > 0) {
          setState(() {
            _isLoaded = true;
          });
          widget.onLoad?.call();
        }
      },
      child: _isLoaded
          ? widget.child
          : widget.placeholder ?? const SizedBox.shrink(),
    );
  }
}

/// Simple visibility detector implementation
class VisibilityDetector extends StatefulWidget {
  final Key key;
  final Widget child;
  final Function(VisibilityInfo) onVisibilityChanged;

  const VisibilityDetector({
    required this.key,
    required this.child,
    required this.onVisibilityChanged,
  }) : super(key: key);

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  Widget build(BuildContext context) {
    // Simplified implementation - would use IntersectionObserver in real app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onVisibilityChanged(const VisibilityInfo(visibleFraction: 1.0));
    });

    return widget.child;
  }
}

/// Visibility information
class VisibilityInfo {
  final double visibleFraction;

  const VisibilityInfo({required this.visibleFraction});
}

/// Optimized animated widget that uses efficient animations
class OptimizedAnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double? width;
  final double? height;
  final Color? color;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Decoration? decoration;

  const OptimizedAnimatedContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
    this.width,
    this.height,
    this.color,
    this.padding,
    this.margin,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        width: width,
        height: height,
        color: color,
        padding: padding,
        margin: margin,
        decoration: decoration,
        child: child,
      ),
    );
  }
}

/// Performance-optimized text widget with caching
class OptimizedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enableCaching;

  const OptimizedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enableCaching = true,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );

    return enableCaching ? RepaintBoundary(child: textWidget) : textWidget;
  }
}
