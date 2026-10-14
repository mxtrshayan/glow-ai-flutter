class Profile {
  String skinTone = '', undertone = '', skinType = '', event = '', time = 'day';
  String outfit = '#D4A0C0', hijab = 'no', style = 'both', owned = '';

  Map<String, dynamic> toJson() => {
    'skin_tone': skinTone,
    'undertone': undertone,
    'skin_type': skinType,
    'event': event,
    'time_of_day': time,
    'outfit_color': outfit,
    'hijab': hijab,
    'style_preference': style,
    'owned_items': owned,
  };
}
