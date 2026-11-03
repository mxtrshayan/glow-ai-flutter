import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class Home extends StatelessWidget {
  final VoidCallback onConsult, onStudio;
  final VoidCallback? onResults;
  final bool active;
  const Home({
    super.key,
    required this.onConsult,
    required this.onStudio,
    this.onResults,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: responsiveBody(
      LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 700;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide) ...[
                eyebrow('AI BEAUTY, MADE PERSONAL'),
                const SizedBox(height: 9),
              ],
              title('Meet your next look.', size: wide ? 40 : 30),
              const SizedBox(height: 9),
              copy('AI recommendations. Virtual makeup.', size: 13),
            ],
          );
          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FeatureAction(
                label: 'AI recommendations',
                detail: 'Find your shades & style',
                icon: Icons.auto_awesome_outlined,
                onTap: onConsult,
                featured: true,
              ),
              const SizedBox(height: 12),
              _FeatureAction(
                label: 'Virtual makeup',
                detail: 'Try it on your photo & save',
                icon: Icons.face_retouching_natural,
                onTap: onStudio,
              ),
              if (onResults != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onResults,
                  icon: const Icon(Icons.favorite_border, size: 18),
                  label: const Text('Revisit my current look'),
                ),
              ],
            ],
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            children: [
              Row(
                children: [
                  title('Glow', size: 29),
                  const Spacer(),
                  Icon(Icons.auto_awesome, size: 20, color: accentOf(context)),
                ],
              ),
              const SizedBox(height: 12),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: MakeupDemo(active: active, aspectRatio: 4 / 5),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          intro,
                          const SizedBox(height: 26),
                          actions,
                          const SizedBox(height: 18),
                          copy(
                            'One photo. A world of possibilities.',
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                intro,
                const SizedBox(height: 14),
                MakeupDemo(active: active, aspectRatio: 1.4),
                const SizedBox(height: 14),
                actions,
              ],
            ],
          );
        },
      ),
    ),
  );
}

class _FeatureAction extends StatelessWidget {
  final String label, detail;
  final IconData icon;
  final VoidCallback onTap;
  final bool featured;
  const _FeatureAction({
    required this.label,
    required this.detail,
    required this.icon,
    required this.onTap,
    this.featured = false,
  });
  @override
  Widget build(BuildContext context) {
    final foreground = featured
        ? Theme.of(context).colorScheme.onPrimary
        : inkOf(context);
    return Material(
      color: featured ? accentOf(context) : surfaceOf(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: featured ? accentOf(context) : borderOf(context),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 74),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: featured
                        ? foreground.withValues(alpha: .12)
                        : accentOf(context).withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: featured ? foreground : accentOf(context),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detail,
                        style: TextStyle(
                          color: featured
                              ? foreground.withValues(alpha: .85)
                              : mutedOf(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: foreground, size: 21),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An illustrative, generated portrait; actual user-photo rendering lives in Studio.
class MakeupDemo extends StatefulWidget {
  final bool active;
  final double aspectRatio;
  const MakeupDemo({super.key, this.active = true, this.aspectRatio = 1.08});
  @override
  State<MakeupDemo> createState() => _MakeupDemoState();
}

class _MakeupDemoState extends State<MakeupDemo> {
  bool paused = false;
  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final animate =
        widget.active && !paused && !reducedMotion && TickerMode.of(context);
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              image: true,
              label:
                  'Illustrative demo: rose lipstick, blush and champagne eye makeup gradually appear on a portrait.',
              child: Image.asset(
                animate
                    ? 'assets/dashboard/makeup-preview-hd.gif'
                    : 'assets/dashboard/makeup-poster.jpg',
                key: ValueKey(animate),
                fit: BoxFit.cover,
                alignment: const Alignment(0, -.1),
                gaplessPlayback: true,
                excludeFromSemantics: true,
                cacheWidth: 1080,
              ),
            ),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB038202C)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              right: 64,
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xEDFDF6F9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'VIRTUAL MAKEUP DEMO',
                    style: TextStyle(
                      color: primary,
                      fontSize: 9,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            if (!reducedMotion)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  tooltip: paused
                      ? 'Play makeup preview'
                      : 'Pause makeup preview',
                  onPressed: () => setState(() => paused = !paused),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0x99462535),
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(
                    paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 21,
                  ),
                ),
              ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title(
                    'See your glow come to life.',
                    size: 21,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final color in const [
                        Color(0xFFB74868),
                        Color(0xFFCE8D88),
                        Color(0xFFD8BC91),
                      ])
                        Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xBFFFFFFF)),
                          ),
                        ),
                      const Text(
                        'Rose & champagne',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
