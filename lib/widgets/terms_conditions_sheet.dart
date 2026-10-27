import 'package:flutter/material.dart';
import '../constants/student_terms.dart';

/// Draggable sheet showing role-based Terms & Conditions.
Future<bool?> showTermsAndConditionsSheet(
  BuildContext context, {
  String role = 'student',
}) {
  final doc = getTermsForRole(role);
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _TermsSheet(doc: doc),
  );
}

class _TermsSheet extends StatefulWidget {
  final TermsDocument doc;
  const _TermsSheet({required this.doc});

  @override
  State<_TermsSheet> createState() => _TermsSheetState();
}

class _TermsSheetState extends State<_TermsSheet> {
  bool _reachedBottom = false;
  bool _needsScroll = false;

  void _updateFromMetrics(ScrollMetrics metrics) {
    final needs = metrics.maxScrollExtent > 8;
    final atBottom =
        !needs || metrics.pixels >= metrics.maxScrollExtent - 24;
    if (needs != _needsScroll || atBottom != _reachedBottom) {
      setState(() {
        _needsScroll = needs;
        _reachedBottom = atBottom;
      });
    }
  }

  bool get _canAgree => !_needsScroll || _reachedBottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor =
        theme.textTheme.titleLarge?.color ?? theme.colorScheme.onSurface;
    final bodyColor = theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.85);
    final surface = theme.colorScheme.surface;
    final borderColor = theme.dividerColor.withValues(alpha: 0.6);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Semantics(
                label: 'Drag handle',
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: 'Terms and conditions',
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF1565C0).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF1565C0),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Student Terms & Conditions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: bodyColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Last updated: ${widget.doc.lastUpdated}  ·  Version ${widget.doc.version}',
                        style: TextStyle(
                          fontSize: 12,
                          color: bodyColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_needsScroll && !_reachedBottom)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Semantics(
                    label: 'Scroll to read all terms',
                    child: Row(
                      children: [
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color:
                              const Color(0xFF1565C0).withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Scroll to read',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1565C0)
                                .withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.axis == Axis.vertical) {
                      _updateFromMetrics(n.metrics);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemCount: widget.doc.sections.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (scrollController.hasClients) {
                            _updateFromMetrics(scrollController.position);
                          }
                        });
                      }
                      final section = widget.doc.sections[index];
                      return _SectionCard(
                        section: section,
                        titleColor: titleColor,
                        bodyColor: bodyColor,
                        borderColor: borderColor,
                      );
                    },
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Close'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _canAgree
                              ? () => Navigator.pop(context, true)
                              : null,
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: const Text('I Agree'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF1565C0)
                                .withValues(alpha: 0.35),
                            disabledForegroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final TermsSection section;
  final Color titleColor;
  final Color bodyColor;
  final Color borderColor;

  const _SectionCard({
    required this.section,
    required this.titleColor,
    required this.bodyColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = section.accent;
    return Semantics(
      header: true,
      label: section.title,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: '${section.title} icon',
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(section.icon, color: accent, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (section.body.isNotEmpty)
              Text(
                section.body,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: bodyColor,
                ),
              ),
            if (section.bullets.isNotEmpty) ...[
              if (section.body.isNotEmpty) const SizedBox(height: 8),
              ...section.bullets.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: accent.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          line,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: bodyColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
