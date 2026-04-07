enum CefrLevel {
  a1('A1', 'Débutant', 1),
  a2('A2', 'Élémentaire', 2),
  b1('B1', 'Intermédiaire', 3),
  b2('B2', 'Intermédiaire avancé', 4),
  c1('C1', 'Avancé', 5),
  c2('C2', 'Maîtrise', 6);

  final String code;
  final String labelFr;
  final int rank;

  const CefrLevel(this.code, this.labelFr, this.rank);

  static CefrLevel fromString(String s) {
    return CefrLevel.values.firstWhere(
      (e) => e.code.toLowerCase() == s.toLowerCase(),
      orElse: () => CefrLevel.b1,
    );
  }
}
