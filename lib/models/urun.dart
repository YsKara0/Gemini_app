class Urun {
  final String isim;
  final double miktar;
  final String miktarTuru;

  Urun(this.isim, this.miktar, this.miktarTuru);

  Urun.fromMap(Map<String, dynamic> json)
      : isim = json['isim']?.toString() ?? '',
        miktar = (json['miktar'] ?? 0).toDouble(),
        miktarTuru = json['miktarTuru']?.toString() ?? 'adet';

  Map<String, dynamic> toMap() {
    return {
      'isim': isim,
      'miktar': miktar,
      'miktarTuru': miktarTuru,
    };
  }

  @override
  String toString() {
    return '$miktar $miktarTuru $isim';
  }
}