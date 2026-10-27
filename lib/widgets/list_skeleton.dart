import 'package:flutter/material.dart';

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

/// Shared body for Firestore list screens: cache-first, skeleton, refresh.
class CachedStreamList<T> extends StatelessWidget {
  final Stream<T> stream;
  final T? initialData;
  final bool Function(T data) isEmpty;
  final String emptyMessage;
  final Widget Function(BuildContext context, T data) builder;
  final Future<void> Function()? onRefresh;
  final String? perfKey;

  const CachedStreamList({
    super.key,
    required this.stream,
    required this.initialData,
    required this.isEmpty,
    required this.emptyMessage,
    required this.builder,
    this.onRefresh,
    this.perfKey,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) {
        if (snapshot.hasError && !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load data.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final waiting =
            snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData &&
                initialData == null;

        if (waiting) {
          return const Column(
            children: [
              LinearProgressIndicator(minHeight: 2),
              Expanded(child: ListSkeleton()),
            ],
          );
        }

        if (!snapshot.hasData) {
          return const ListSkeleton();
        }

        final data = snapshot.data as T;
        if (isEmpty(data)) {
          final empty = Center(child: Text(emptyMessage));
          if (onRefresh == null) return empty;
          return RefreshIndicator(
            onRefresh: onRefresh!,
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

        final child = builder(context, data);
        if (onRefresh == null) return child;
        return RefreshIndicator(
          onRefresh: onRefresh!,
          child: child,
        );
      },
    );
  }
}
