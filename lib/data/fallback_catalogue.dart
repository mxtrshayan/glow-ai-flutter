class FallbackRecipe {
  final String label;
  final List<String> lips;
  final List<String> eyes;
  final List<String> blushes;
  final List<String> outfits;
  final List<String> accessories;

  const FallbackRecipe({
    required this.label,
    required this.lips,
    required this.eyes,
    required this.blushes,
    required this.outfits,
    required this.accessories,
  });
}

const fallbackRecipes = <String, FallbackRecipe>{
  'wedding': FallbackRecipe(
    label: 'wedding celebrations',
    lips: ['Deep Rose|#AC3B56', 'Berry Silk|#8B1E3F', 'Nude Rose|#B85C70'],
    eyes: [
      'golden brown with champagne shimmer|#9E784F',
      'soft bronze with gold light|#A46643',
      'plum brown with shimmer|#80506A',
    ],
    blushes: [
      'soft rose pink|#D4707F',
      'dusty rose|#BD7B89',
      'peach rose|#D98983',
    ],
    outfits: [
      'an embroidered lehenga',
      'a rich formal shalwar kameez',
      'a jewel-toned sharara',
    ],
    accessories: [
      'gold polki earrings',
      'a delicate necklace with bangles',
      'a pearl and gold jhumka set',
    ],
  ),
  'mehndi': FallbackRecipe(
    label: 'a colourful mehndi',
    lips: ['Tangerine Blaze|#E0412B', 'Coral Pop|#D94B4B', 'Hot Pink|#D1246C'],
    eyes: [
      'green or yellow shimmer|#8B8C3A',
      'copper with a bright accent|#B26E45',
      'purple-pink shimmer|#8E4A7D',
    ],
    blushes: ['bright coral|#E86F58', 'warm coral|#E47762', 'hot pink|#E0487C'],
    outfits: [
      'a bright gharara',
      'a colourful printed shalwar kameez',
      'a cheerful lehenga',
    ],
    accessories: [
      'colourful jhumkas',
      'floral jewellery with bangles',
      'playful statement earrings',
    ],
  ),
  'eid': FallbackRecipe(
    label: 'Eid visits',
    lips: ['Petal Rose|#C95B72', 'Soft Coral|#D84F5F', 'Rose Balm|#DC7C85'],
    eyes: [
      'copper brown with nude highlight|#A46643',
      'warm bronze wash|#A8795C',
      'champagne taupe|#99827B',
    ],
    blushes: ['peach pink|#E5827D', 'soft peach|#EB9884', 'dusty rose|#BD7B89'],
    outfits: [
      'a pastel embroidered suit',
      'a bright sharara',
      'a refined shalwar kameez',
    ],
    accessories: [
      'simple gold earrings',
      'thin bangles with a delicate bracelet',
      'a small matching clutch',
    ],
  ),
  'party': FallbackRecipe(
    label: 'a party',
    lips: ['Berry Bold|#8B1E3F', 'Deep Plum|#702044', 'Ruby Matte|#B52D4C'],
    eyes: [
      'smoky black with bronze shimmer|#3D3835',
      'plum smoke with sparkle|#62435F',
      'bronze cut crease|#966247',
    ],
    blushes: ['deep rose|#C2526E', 'berry flush|#A94D68', 'warm mauve|#B56D73'],
    outfits: [
      'an elegant sharara',
      'an embroidered formal suit',
      'a sleek evening dress',
    ],
    accessories: [
      'statement earrings',
      'a bold cuff with rings',
      'a sculptural clutch',
    ],
  ),
};

const fallbackDefault = FallbackRecipe(
  label: 'everyday life',
  lips: ['Sheer Blush|#DC7C85', 'Bare Blush|#D67D89', 'Warm Petal|#D4776C'],
  eyes: [
    'a light nude wash|#CBB2A3',
    'nude peach wash|#CFA18C',
    'soft bronze wash|#A8795C',
  ],
  blushes: [
    'soft peach|#EB9884',
    'soft baby pink|#F4A6B6',
    'warm peach|#E58B78',
  ],
  outfits: [
    'a comfortable cotton suit',
    'casual jeans with a soft top',
    'a relaxed printed outfit',
  ],
  accessories: ['simple earrings', 'small hoops', 'a simple watch'],
);
