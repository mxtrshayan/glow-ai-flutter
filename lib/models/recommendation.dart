class Recommendation {
  final Map<String, Map<String, String>> sections;
  final String overall;
  final bool fromAi;

  const Recommendation(this.sections, this.overall, {this.fromAi = false});
}
