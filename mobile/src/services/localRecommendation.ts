import type { GlowAIRecommendation, UserProfileInput, WeatherData } from "../types";

type Recipe = {
  label: string;
  mood: string;
  blush: [string, string];
  eyeshadow: [string, string];
  lipstick: [string, string, string];
  dressing: string[];
  dupatta: string[];
  footwear: string[];
  jewellery: string[];
  hair: string[];
};

const tones = ["porcelain", "very fair", "fair", "light", "light medium", "medium / wheatish", "tan", "brown", "deep", "rich"];
const lensByTone: Record<string, string> = {
  porcelain: "soft blue or violet", "very fair": "grey or soft blue", fair: "hazel or soft green",
  light: "honey brown or warm hazel", "light medium": "golden hazel or honey brown",
  "medium / wheatish": "warm honey or light brown", tan: "golden brown or amber",
  brown: "dark honey or copper", deep: "dark brown or subtle bronze", rich: "deep brown or onyx",
};

const recipes: Record<string, Recipe> = {
  wedding: { label: "wedding celebrations", mood: "polished and luminous", blush: ["soft rose pink", "#D4707F"], eyeshadow: ["golden brown with champagne shimmer", "#9E784F"], lipstick: ["Deep Rose", "deep rose satin", "#AC3B56"], dressing: ["an embroidered lehenga", "a rich formal shalwar kameez", "a jewel-toned sharara"], dupatta: ["a gold-edged chiffon dupatta", "a heavily embroidered dupatta"], footwear: ["gold heels", "embroidered khussa"], jewellery: ["gold polki earrings", "a delicate necklace with bangles"], hair: ["an elegant updo", "loose romantic curls"] },
  mehndi: { label: "a colourful mehndi", mood: "bright and playful", blush: ["bright coral", "#E86F58"], eyeshadow: ["green or yellow shimmer", "#8B8C3A"], lipstick: ["Tangerine Blaze", "bright orange-red matte", "#E0412B"], dressing: ["a bright gharara", "a colourful printed shalwar kameez", "a cheerful lehenga"], dupatta: ["a mirror-work dupatta", "a bright contrast dupatta"], footwear: ["colourful khussa", "comfortable block heels"], jewellery: ["colourful jhumkas", "floral jewellery with bangles"], hair: ["loose curls with flowers", "a braided half-up style"] },
  dholki: { label: "a joyful dholki", mood: "fun and expressive", blush: ["hot pink", "#E0487C"], eyeshadow: ["purple-pink shimmer", "#8E4A7D"], lipstick: ["Hot Fuchsia", "hot pink satin", "#D1246C"], dressing: ["a colourful printed suit", "a bright embroidered outfit"], dupatta: ["a bright contrast dupatta", "a light cotton dupatta"], footwear: ["colourful block heels", "embroidered khussa"], jewellery: ["colourful jhumkas and bangles", "playful statement earrings"], hair: ["loose waves", "a high ponytail with colour"] },
  eid: { label: "Eid visits", mood: "fresh and elegant", blush: ["peach pink", "#E5827D"], eyeshadow: ["copper brown with nude highlight", "#A46643"], lipstick: ["Petal Rose", "soft rose satin", "#C95B72"], dressing: ["a pastel embroidered suit", "a bright sharara", "a refined shalwar kameez"], dupatta: ["a matching silk dupatta", "a soft chiffon dupatta"], footwear: ["nude heels", "gold khussa"], jewellery: ["simple gold earrings", "thin bangles with a delicate bracelet"], hair: ["soft curls", "a neat blowout"] },
  valima: { label: "a formal Valima", mood: "soft and sophisticated", blush: ["dusty rose", "#BD7B89"], eyeshadow: ["taupe with champagne light", "#99827B"], lipstick: ["Muted Mauve", "mauve satin", "#A75D6E"], dressing: ["an elegant pastel formal suit", "a softly embellished saree"], dupatta: ["a sheer chiffon dupatta with a border", "a graceful silk dupatta"], footwear: ["nude heels", "delicate gold sandals"], jewellery: ["pearl earrings", "a fine gold bracelet"], hair: ["a low polished bun", "soft brushed waves"] },
  everyday: { label: "everyday life", mood: "natural and effortless", blush: ["soft peach", "#EB9884"], eyeshadow: ["a light nude wash", "#CBB2A3"], lipstick: ["Sheer Blush", "sheer pink balm", "#DC7C85"], dressing: ["a comfortable cotton suit", "casual jeans with a soft top"], dupatta: ["a light cotton dupatta", "a simple scarf"], footwear: ["comfortable flats", "clean white trainers"], jewellery: ["simple earrings", "small hoops"], hair: ["natural loose hair", "a casual bun"] },
  university: { label: "university days", mood: "fresh and practical", blush: ["soft baby pink", "#F4A6B6"], eyeshadow: ["nude peach wash", "#CFA18C"], lipstick: ["Bare Blush", "light nude pink balm", "#D67D89"], dressing: ["a simple printed suit", "jeans with a polished blouse"], dupatta: ["a simple cotton dupatta", "a lightweight scarf"], footwear: ["white sneakers", "comfortable flats"], jewellery: ["small studs", "simple hoops"], hair: ["a practical ponytail", "a casual half-up style"] },
  office: { label: "the office", mood: "neat and quietly polished", blush: ["soft mauve", "#BD7B89"], eyeshadow: ["neutral taupe", "#99827B"], lipstick: ["Office Rose", "muted mauve satin", "#A75D6E"], dressing: ["a solid-colour formal suit", "a tailored blazer with trousers"], dupatta: ["a plain silk scarf", "a subtle dupatta"], footwear: ["block heels", "polished loafers"], jewellery: ["pearl studs", "small gold earrings"], hair: ["a neat low ponytail", "a polished bun"] },
  shopping: { label: "a shopping day", mood: "comfortable with a little colour", blush: ["warm peach", "#E58B78"], eyeshadow: ["soft bronze wash", "#A8795C"], lipstick: ["Warm Petal", "tinted coral balm", "#D4776C"], dressing: ["a relaxed cotton suit", "wide-leg trousers with a breezy blouse"], dupatta: ["a light printed dupatta", "a relaxed scarf"], footwear: ["cushioned sandals", "clean trainers"], jewellery: ["small hoops", "a simple watch"], hair: ["a relaxed ponytail", "a comfortable braid"] },
  party: { label: "a party", mood: "confident and defined", blush: ["deep rose", "#C2526E"], eyeshadow: ["smoky black with bronze shimmer", "#3D3835"], lipstick: ["Berry Bold", "bold berry matte", "#8B1E3F"], dressing: ["an elegant sharara", "an embroidered formal suit", "a sleek evening dress"], dupatta: ["a sheer evening dupatta", "a dramatic drape"], footwear: ["strappy heels", "embellished sandals"], jewellery: ["statement earrings", "a bold cuff with rings"], hair: ["sleek straight hair", "voluminous curls"] },
  date: { label: "a romantic date", mood: "soft and luminous", blush: ["soft coral", "#E57C72"], eyeshadow: ["warm rose with gold light", "#B56D73"], lipstick: ["Coral Kiss", "coral rose satin", "#D84F5F"], dressing: ["a soft pastel suit", "a floral midi dress"], dupatta: ["a light chiffon dupatta", "a relaxed soft scarf"], footwear: ["nude block heels", "white sandals"], jewellery: ["delicate earrings", "a fine charm bracelet"], hair: ["soft romantic waves", "a neat half-up style"] },
  photoshoot: { label: "a photoshoot", mood: "camera-ready and sculpted", blush: ["rose peach", "#D87878"], eyeshadow: ["bronzed brown with a bright inner corner", "#966247"], lipstick: ["Camera Rose", "rose satin", "#C45468"], dressing: ["a colour-blocked formal look", "an embroidered statement outfit"], dupatta: ["a clean editorial drape", "a silk dupatta with a defined edge"], footwear: ["nude heels", "a refined embellished sandal"], jewellery: ["one statement pair of earrings", "a sculptural bracelet"], hair: ["defined waves", "a clean sleek style"] },
  festival: { label: "a festival or concert", mood: "bold and joyful", blush: ["warm coral", "#E47762"], eyeshadow: ["copper with a colourful accent", "#B26E45"], lipstick: ["Festival Poppy", "bright coral satin", "#D94B4B"], dressing: ["a vivid printed outfit", "a bright embroidered suit"], dupatta: ["a playful contrast dupatta", "a lightweight colourful scarf"], footwear: ["comfortable metallic sandals", "bright khussa"], jewellery: ["layered earrings", "colourful bangles"], hair: ["loose textured waves", "a high ponytail"] },
};

const undertoneTips: Record<string, { metals: string; direction: string }> = {
  warm: { metals: "gold jewellery", direction: "peach, coral, bronze, and warm rose" },
  cool: { metals: "silver or white-gold jewellery", direction: "mauve, berry, plum, and cool rose" },
  neutral: { metals: "gold or silver jewellery", direction: "balanced rose, nude, and soft bronze" },
  olive: { metals: "antique gold jewellery", direction: "terracotta, olive, bronze, and muted rose" },
};
const skinTypeTips: Record<string, { primer: string; base: string; setting: string }> = {
  oily: { primer: "oil-free mattifying primer", base: "lightweight soft-matte base", setting: "translucent powder through the centre and long-wear spray" },
  dry: { primer: "hydrating primer", base: "hydrating satin base", setting: "a fine dewy setting mist" },
  combination: { primer: "balancing primer", base: "satin base with light coverage", setting: "powder only where shine appears" },
  sensitive: { primer: "fragrance-free soothing primer", base: "gentle light satin base", setting: "a minimal fragrance-free setting mist" },
  normal: { primer: "comfortable smoothing primer", base: "light satin base", setting: "satin setting spray" },
};
const styleTips: Record<string, string> = {
  traditional: "Keep the silhouette graceful with coordinated colour and one refined focal detail.",
  both: "Blend familiar traditional details with one clean modern accent.",
  western: "Keep the lines clean and let the colour story carry the look.",
};
const weatherTips: Record<string, string> = {
  rainy: "Use waterproof mascara, waterproof liner, and a long-wear setting spray.",
  hot_humid: "Choose oil-free layers, blotting sheets, and a light setting spray.",
  cold: "Moisturise generously before makeup and keep a nourishing lip balm nearby.",
  mild: "A satin or softly dewy finish should wear beautifully in this weather.",
};

export const OFFLINE_VARIANT_COUNT = 13 * 10 * 4 * 5 * 4 * 3 * 2 * 24;

function pick<T>(items: T[], seed: string): T {
  let hash = 2166136261;
  for (const character of seed) hash = Math.imul(hash ^ character.charCodeAt(0), 16777619);
  return items[Math.abs(hash) % items.length];
}
function title(value: string) {
  return value.replaceAll("_", " ").replace(/^./, (character) => character.toUpperCase());
}

export function localRecommendation(profile: UserProfileInput, weather?: WeatherData): GlowAIRecommendation {
  const event = recipes[profile.event] ? profile.event : "everyday";
  const recipe = recipes[event];
  const tone = tones.includes(profile.skin_tone) ? profile.skin_tone : "medium / wheatish";
  const undertone = undertoneTips[profile.undertone] ? profile.undertone : "neutral";
  const skinType = skinTypeTips[profile.skin_type] ? profile.skin_type : "normal";
  const typeAdvice = skinTypeTips[skinType];
  const undertoneAdvice = undertoneTips[undertone];
  const seed = [event, tone, undertone, skinType, profile.time_of_day, profile.style_preference, profile.hijab, profile.outfit_color].join("|");
  const finish = profile.time_of_day === "night" || profile.time_of_day === "evening" ? "satin-matte" : "dewy satin";
  const ownItems = profile.owned_items.trim();
  const hair = profile.hijab === "yes"
    ? `${pick(["a chiffon hijab", "a silk hijab", "a softly pleated hijab"], seed)} with ${pick(["pearl pins", "a small brooch", "minimal pins"], seed + "pin")}`
    : pick(recipe.hair, seed + "hair");
  const weatherTip = weather ? (weatherTips[weather.category] ?? `For ${weather.condition.toLowerCase()}, use light layers and refresh as needed.`) : "Weather is not included, so keep a setting spray ready if the day turns humid.";
  const productNote = ownItems ? `Start with what you already own: ${ownItems.slice(0, 140)}. Add only the ${recipe.mood} pieces you are missing.` : `Look for ${undertoneAdvice.direction} when choosing new products.`;
  const blush = recipe.blush;
  const eyeshadow = recipe.eyeshadow;
  const lip = recipe.lipstick;

  return {
    skin_analysis: { detected_tone: title(tone), undertone: title(undertone), finish },
    face: {
      foundation: typeAdvice.base,
      concealer: undertone === "cool" ? "soft peach corrector under the eyes, then a close skin match" : "a close skin-match concealer under the eyes",
      blush: blush[0], blush_hex: blush[1], highlight: `${undertoneAdvice.direction.split(",")[0]} highlight on the high points`,
      contour: profile.time_of_day === "day" || profile.time_of_day === "morning" ? "keep contour sheer and softly blended" : "add a softly defined contour along the cheekbones",
      primer: typeAdvice.primer, setting: typeAdvice.setting,
      tip: `${title(skinType)} skin: build thin layers and let each layer settle before adding more.`,
    },
    eyes: {
      eyeshadow: eyeshadow[0], eyeshadow_hex: eyeshadow[1],
      eyeliner: profile.time_of_day === "night" ? "black kajal with a softly lifted wing" : "brown-black kajal with a slim upper-lash line",
      eyeliner_hex: "#1C1C1C", mascara: event === "everyday" || event === "university" ? "lengthening brown-black mascara" : "lengthening black mascara",
      brows: "fill only sparse areas with a soft natural arch", tip: `Use ${undertoneAdvice.metals} as the small detail that ties the eye look together.`,
    },
    lips: {
      liner: undertone === "cool" ? "mauve rose liner" : "neutral rose liner", lipstick: lip[1], shade_name: lip[0], hex: lip[2], gloss: event === "party" || event === "wedding" ? "skip gloss for longer wear" : "clear gloss at the centre", tip: `The ${lip[0]} shade balances the ${recipe.mood} direction without overpowering it.`,
    },
    outfit: {
      dressing: `${pick(recipe.dressing, seed + "dress")} in or alongside ${profile.outfit_color || "your chosen colour"}.`,
      dupatta: profile.style_preference === "western" ? "Skip the dupatta or use a clean lightweight scarf." : pick(recipe.dupatta, seed + "dupatta"),
      footwear: pick(recipe.footwear, seed + "shoes"), style_note: styleTips[profile.style_preference],
    },
    accessories: { jewellery: `${pick(recipe.jewellery, seed + "jewellery")} in ${undertoneAdvice.metals}.`, bag: event === "everyday" || event === "university" ? "a practical shoulder bag or tote" : "a small bag that echoes one outfit colour", extra: productNote },
    brands: {
      foundation_brand: skinType === "sensitive" ? "Clinique or La Roche-Posay" : skinType === "oily" ? "Maybelline Fit Me Matte + Poreless or Huda Beauty FauxFilter" : "Maybelline Fit Me or Huda Beauty FauxFilter",
      lip_brand: "Charlotte Tilbury Pillow Talk or L'Oreal Color Riche", eye_brand: "Maybelline Sky High mascara and Essence eyeliner", blush_brand: "NARS Orgasm or e.l.f. Monochromatic Multi-Stick", drugstore_pick: "L'Oreal Infallible 24H", tip: `${title(skinType)} skin usually benefits from ${typeAdvice.base}; patch-test new products if your skin is reactive.`,
    },
    lens: { color: lensByTone[tone] ?? "warm honey or light brown", brand_suggestion: "FreshLook Illuminate or Solotica Hidrocor", reason: `${lensByTone[tone] ?? "Warm honey"} lenses complement ${tone} skin and the ${recipe.mood} palette.`, tip: "Always use lens-safe drops and never sleep in lenses." },
    hair_hijab: { style: hair, color_suggestion: `Echo ${profile.outfit_color || "the outfit colour"} softly, or choose a neutral that lets the face stay the focus.`, accessory: pick(recipe.jewellery, seed + "hair accessory"), tip: "Keep the style secure, comfortable, and easy to refresh." },
    weather_tip: weatherTip,
    overall_tip: `A ${recipe.mood} look designed for ${recipe.label}; confidence is your best accessory.`,
    status: "fallback",
    inputs_received: { ...profile, image: "processed locally; not uploaded", weather: weather ? "provided locally" : "not provided" },
  };
}
