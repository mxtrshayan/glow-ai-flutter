import '../data/fallback_catalogue.dart';
import '../models/profile.dart';
import '../models/recommendation.dart';

class FallbackRecommendationService {
  const FallbackRecommendationService();

  Recommendation create(Profile profile) {
    final recipe = fallbackRecipes[profile.event] ?? fallbackDefault;
    final seed = _seed(profile);
    String choose(List<String> values, int offset) =>
        values[(seed + offset) % values.length];
    String name(String value) => value.split('|').first;
    String hex(String value) => value.split('|').last;
    final lip = choose(recipe.lips, 1);
    final eye = choose(recipe.eyes, 2);
    final blush = choose(recipe.blushes, 3);
    final metal = profile.undertone == 'cool'
        ? 'silver or white-gold'
        : profile.undertone == 'olive'
        ? 'antique gold'
        : 'gold';
    final style = profile.style == 'traditional'
        ? 'rooted and elegant'
        : profile.style == 'western'
        ? 'fresh and modern'
        : 'entirely like you';
    final sections = <String, Map<String, String>>{
      'skin_analysis': {
        'skin tone': profile.skinTone.isEmpty
            ? 'Your portrait can refine this further.'
            : profile.skinTone,
        'undertone': profile.undertone.isEmpty
            ? 'neutral-friendly shades'
            : profile.undertone,
        'skin type': profile.skinType.isEmpty
            ? 'balanced preparation'
            : profile.skinType,
        'finish': profile.skinType == 'oily'
            ? 'soft matte and finely set'
            : 'fresh satin skin',
      },
      'face': {
        'foundation': 'A breathable, skin-like base matched to your tone',
        'blush': 'Blend ${name(blush)} high on the cheeks',
        'blush_hex': hex(blush),
        'highlight': profile.time == 'night'
            ? 'soft champagne highlight'
            : 'subtle liquid glow',
      },
      'eyes': {
        'eyeshadow': name(eye),
        'eyeshadow_hex': hex(eye),
        'eyeliner': profile.time == 'night'
            ? 'defined winged liner'
            : 'soft upper-lash definition',
        'eyeliner_hex': '#1A1A1A',
        'mascara': 'lengthening black mascara',
      },
      'lips': {
        'shade': name(lip),
        'finish': profile.time == 'night'
            ? 'long-wear satin matte'
            : 'comfortable satin',
        'hex': hex(lip),
      },
      'outfit': {
        'direction': 'Coordinate with your ${profile.outfit} outfit',
        'styling': choose(recipe.outfits, 4),
        'dupatta': profile.hijab == 'yes'
            ? 'a softly framed matching chiffon drape'
            : 'a light scarf or clean neckline',
      },
      'accessories': {
        'jewellery': '$metal jewellery',
        'finishing touch': choose(recipe.accessories, 5),
      },
      'brands': {
        'shelf edit': profile.owned.isEmpty
            ? 'Start with a comfortable base, rose blush and a versatile lip.'
            : 'Build around the pieces you already own: ${profile.owned}',
      },
      'lens': {
        'suggestion': _lens(profile.skinTone),
        'tip': 'Always use lens-safe drops and never sleep in lenses.',
      },
      'hair_hijab': {
        'styling': profile.hijab == 'yes'
            ? 'A graceful drape with softly framed features'
            : profile.style == 'western'
            ? 'Soft waves with a clean modern finish'
            : 'Soft waves or a neat polished style',
      },
    };
    return Recommendation(
      sections,
      'Your ${recipe.label} look is designed to feel $style. This edit combines ${name(lip)}, ${name(blush)} and ${name(eye)} for a considered, wearable result.',
    );
  }

  int _seed(Profile p) => Object.hash(
    p.skinTone,
    p.undertone,
    p.skinType,
    p.event,
    p.time,
    p.outfit,
    p.hijab,
    p.style,
    p.owned,
  ).abs();

  String _lens(String tone) {
    if (tone.contains('deep') || tone.contains('rich')) {
      return 'dark honey, copper or subtle bronze';
    }
    if (tone.contains('tan') || tone.contains('brown')) {
      return 'golden brown or amber';
    }
    if (tone.contains('fair')) return 'hazel or soft green';
    return 'warm honey or light brown';
  }
}
