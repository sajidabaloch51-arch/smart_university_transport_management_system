import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/firestore_error_messages.dart';

/// Shared loading / error / empty / data shell for Firestore-backed screens.
class AsyncStateView<T> extends StatefulWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data) isEmpty;
  final String emptyMessage;
  final String? emptySubtitle;
  final VoidCallback? onRetry;
  final Duration timeout;
  final T? initialData;

  const AsyncStateView({
    super.key,
    required this.stream,
    required this.builder,
    required this.isEmpty,
    required this.emptyMessage,
    this.emptySubtitle,
    this.onRetry,
    this.timeout = const Duration(seconds: 12),
    this.initialData,
  });

  @override
  State<AsyncStateView<T>> createState() => _AsyncStateViewState<T>();
}

class _AsyncStateViewState<T> extends State<AsyncStateView<T>> {
  Timer? _timeoutTimer;
  bool _timedOut = false;
  Object? _lastError;
  int _retryToken = 0;

  @override
  void initState() {
    super.initState();
    _armTimeout();
  }

  @override
  void didUpdateWidget(covariant AsyncStateView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _timedOut = false;
      _lastError = null;
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
      if (!_timedOut) {
        setState(() {
          _timedOut = true;
          _lastError ??= TimeoutException(
            "Can't reach the server. Check your connection",
          );
        });
      }
    });
  }

  void _retry() {
    setState(() {
      _timedOut = false;
      _lastError = null;
      _retryToken++;
    });
    _armTimeout();
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      key: ValueKey('async-$_retryToken'),
      stream: widget.stream,
      initialData: widget.initialData,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _timeoutTimer?.cancel();
          _lastError = snapshot.error;
          debugPrint('AsyncStateView error: ${snapshot.error}');
          return _ErrorPane(
            message: FirestoreErrorMessages.friendly(snapshot.error!),
            onRetry: _retry,
          );
        }

        if (snapshot.hasData) {
          _timeoutTimer?.cancel();
          _timedOut = false;
          final data = snapshot.data as T;
          if (widget.isEmpty(data)) {
            return _EmptyPane(
              message: widget.emptyMessage,
              subtitle: widget.emptySubtitle,
              onRetry: widget.onRetry == null ? null : _retry,
            );
          }
          return widget.builder(context, data);
        }

        if (_timedOut) {
          return _ErrorPane(
            message: FirestoreErrorMessages.friendly(
              _lastError ??
                  TimeoutException(
                    "Can't reach the server. Check your connection",
                  ),
            ),
            onRetry: _retry,
          );
        }

        return const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      },
    );
  }
}

class _ErrorPane extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPane({required this.message, required this.onRetry});

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
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPane extends StatelessWidget {
  final String message;
  final String? subtitle;
  final VoidCallback? onRetry;

  const _EmptyPane({
    required this.message,
    this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
