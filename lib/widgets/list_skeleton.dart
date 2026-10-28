import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/firestore_error_messages.dart';

/// Lightweight skeleton cards (no extra package) for list screens.
class ListSkeleton extends StatefulWidget {
  final int itemCount;
  const ListSkeleton({super.key, this.itemCount = 6});

  @override
  State<ListSkeleton> createState() => _ListSkeletonState();
}

class _ListSkeletonState extends State<ListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = 0.35 + (_c.value * 0.35);
        final color = Colors.grey.shade300.withValues(alpha: t);
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: widget.itemCount,
          itemBuilder: (_, __) => Container(
            height: 88,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}

/// Shared body for Firestore list screens: cache-first, skeleton, timeout, refresh.
///
/// [timeout] applies only to the first snapshot (cancelled once data or error
/// arrives). Default 15s — the previous 5s raced LiveFirestore's cold fetch.
class CachedStreamList<T> extends StatefulWidget {
  final Stream<T> stream;
  final T? initialData;
  final bool Function(T data) isEmpty;
  final String emptyMessage;
  final Widget Function(BuildContext context, T data) builder;
  final Future<void> Function()? onRefresh;
  final String? perfKey;
  final Duration timeout;

  const CachedStreamList({
    super.key,
    required this.stream,
    required this.initialData,
    required this.isEmpty,
    required this.emptyMessage,
    required this.builder,
    this.onRefresh,
    this.perfKey,
    this.timeout = const Duration(seconds: 15),
  });

  @override
  State<CachedStreamList<T>> createState() => _CachedStreamListState<T>();
}

class _CachedStreamListState<T> extends State<CachedStreamList<T>> {
  Timer? _timeoutTimer;
  bool _timedOut = false;
  Object? _lastError;
  StackTrace? _lastStack;
  String? _resolvedMessage;
  int _retryToken = 0;

  @override
  void initState() {
    super.initState();
    _armTimeout();
  }

  @override
  void didUpdateWidget(covariant CachedStreamList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _timedOut = false;
      _lastError = null;
      _lastStack = null;
      _resolvedMessage = null;
      _armTimeout();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _armTimeout() {
    _timeoutTimer?.cancel();
    if (widget.initialData != null) return;
    _timeoutTimer = Timer(widget.timeout, () {
      if (!mounted) return;
      final err = _lastError ??
          TimeoutException('This is taking longer than usual');
      setState(() {
        _timedOut = true;
        _lastError = err;
      });
      _resolveMessage(err, _lastStack);
    });
  }

  Future<void> _resolveMessage(Object error, StackTrace? stack) async {
    final msg = await FirestoreErrorMessages.friendlyAsync(error, stack);
    if (!mounted) return;
    setState(() => _resolvedMessage = msg);
  }

  Future<void> _retry() async {
    setState(() {
      _timedOut = false;
      _lastError = null;
      _lastStack = null;
      _resolvedMessage = null;
      _retryToken++;
    });
    _armTimeout();
    if (widget.onRefresh != null) {
      try {
        await widget.onRefresh!();
      } catch (e, st) {
        debugPrint('CachedStreamList refresh failed: $e\n$st');
        if (mounted) {
          setState(() {
            _lastError = e;
            _lastStack = st;
            _timedOut = true;
          });
          await _resolveMessage(e, st);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      key: ValueKey('cached-list-$_retryToken'),
      stream: widget.stream,
      initialData: widget.initialData,
      builder: (context, snapshot) {
        if (snapshot.hasError && !snapshot.hasData) {
          _timeoutTimer?.cancel();
          _lastError = snapshot.error;
          _lastStack = snapshot.stackTrace;
          // ignore: discarded_futures
          _resolveMessage(snapshot.error!, snapshot.stackTrace);
          return _ErrorBody(
            message: _resolvedMessage ??
                FirestoreErrorMessages.friendly(
                  snapshot.error!,
                  snapshot.stackTrace,
                ),
            details: kDebugMode
                ? FirestoreErrorMessages.debugDetails(snapshot.error!)
                : null,
            onRetry: _retry,
          );
        }

        if (snapshot.hasData) {
          _timeoutTimer?.cancel();
          _timedOut = false;
          final data = snapshot.data as T;
          if (widget.isEmpty(data)) {
            final empty = Center(child: Text(widget.emptyMessage));
            if (widget.onRefresh == null) return empty;
            return RefreshIndicator(
              onRefresh: widget.onRefresh!,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.4,
                    child: empty,
                  ),
                ],
              ),
            );
          }

          final child = widget.builder(context, data);
          if (widget.onRefresh == null) return child;
          return RefreshIndicator(
            onRefresh: widget.onRefresh!,
            child: child,
          );
        }

        if (_timedOut) {
          final err = _lastError ??
              TimeoutException('This is taking longer than usual');
          return _ErrorBody(
            message: _resolvedMessage ??
                FirestoreErrorMessages.friendly(err, _lastStack),
            details: kDebugMode
                ? FirestoreErrorMessages.debugDetails(err)
                : null,
            onRetry: _retry,
          );
        }

        return const Column(
          children: [
            LinearProgressIndicator(minHeight: 2),
            Expanded(child: ListSkeleton()),
          ],
        );
      },
    );
  }
}

class _ErrorBody extends StatefulWidget {
  final String message;
  final String? details;
  final Future<void> Function() onRetry;

  const _ErrorBody({
    required this.message,
    required this.onRetry,
    this.details,
  });

  @override
  State<_ErrorBody> createState() => _ErrorBodyState();
}

class _ErrorBodyState extends State<_ErrorBody> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 40, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF334155)),
            ),
            if (widget.details != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Hide details' : 'Details'),
              ),
              if (_expanded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    widget.details!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => widget.onRetry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
