import 'dart:convert';

enum Laras {
  salendro('salendro', 'Salendro');

  final String id;
  final String label;

  const Laras(this.id, this.label);

  static Laras fromId(String id) =>
      values.firstWhere((value) => value.id == id, orElse: () => salendro);
}

enum ModeNotasi {
  angka('angka', 'Notasi Angka'),
  solfeg('solfeg', 'Daminatila');

  final String id;
  final String label;

  const ModeNotasi(this.id, this.label);

  static ModeNotasi fromId(String id) =>
      values.firstWhere((value) => value.id == id, orElse: () => angka);
}

enum ModeTema {
  terang('terang', 'Terang'),
  gelap('gelap', 'Gelap');

  final String id;
  final String label;

  const ModeTema(this.id, this.label);

  static ModeTema fromId(String id) =>
      values.firstWhere((value) => value.id == id, orElse: () => terang);
}

/// Pilihan instrumen saron. Pada mode [auto], instrumen ditentukan oleh oktaf
/// nada: oktaf rendah memakai Demung, oktaf tengah Saron, oktaf tinggi Peking.
enum PilihanInstrumen {
  auto('auto', 'Otomatis'),
  demung('demung', 'Demung'),
  saron('saron', 'Saron'),
  peking('peking', 'Peking');

  final String id;
  final String label;

  const PilihanInstrumen(this.id, this.label);

  static PilihanInstrumen fromId(String id) =>
      values.firstWhere((value) => value.id == id, orElse: () => auto);
}

/// Cara memukul wilahan: [muka] dibiarkan bergetar, [tengkep] ditekep/diredam.
enum Artikulasi {
  muka('muka', 'Open'),
  tengkep('tengkep', 'Tengkep');

  final String id;
  final String label;

  const Artikulasi(this.id, this.label);

  static Artikulasi fromId(String id) =>
      values.firstWhere((value) => value.id == id, orElse: () => muka);
}

enum JenisLatihan {
  dengar('dengar', 'Latihan Dengar'),
  tebakLaras('tebak_laras', 'Tebak Laras'),
  bacaNotasi('baca_notasi', 'Baca Notasi Angka'),
  solfeg('solfeg', 'Nama Nada Daminatila'),
  ketukIrama('ketuk_irama', 'Ketuk Irama'),
  memoriMelodi('memori_melodi', 'Memori Melodi'),
  dikte('dikte', 'Dikte Sederhana'),
  suaraSendiri('suara_sendiri', 'Suara Sendiri');

  final String id;
  final String label;

  const JenisLatihan(this.id, this.label);

  static JenisLatihan fromId(String id) =>
      values.firstWhere((value) => value.id == id, orElse: () => dengar);
}

enum JenisAcuan {
  tanggaNada('tangga_nada'),
  tonaPatokan('tona_patokan'),
  polaContoh('pola_contoh'),
  polaIrama('pola_irama');

  final String id;

  const JenisAcuan(this.id);

  static JenisAcuan fromId(String id) =>
      values.firstWhere((value) => value.id == id, orElse: () => tanggaNada);
}

enum ArahTangga {
  menurun('menurun'),
  naik('naik');

  final String id;

  const ArahTangga(this.id);

  static ArahTangga fromId(String id) =>
      values.firstWhere((value) => value.id == id, orElse: () => menurun);
}

enum ModePutarAcuan {
  otomatis('otomatis'),
  atasPermintaan('atas_permintaan');

  final String id;

  const ModePutarAcuan(this.id);

  static ModePutarAcuan fromId(String id) =>
      values.firstWhere((value) => value.id == id, orElse: () => otomatis);
}

enum ModeInput {
  pilihOpsi('pilih_opsi'),
  ketuk('ketuk'),
  nyanyi('nyanyi'),
  tulisNotasi('tulis_notasi'),
  susunUrutan('susun_urutan');

  final String id;

  const ModeInput(this.id);

  static ModeInput fromId(String id) =>
      values.firstWhere((value) => value.id == id, orElse: () => pilihOpsi);
}

enum JenisStimulus {
  tona('tona'),
  urutanTona('urutan_tona'),
  polaIrama('pola_irama'),
  laras('laras');

  final String id;

  const JenisStimulus(this.id);

  static JenisStimulus fromId(String id) =>
      values.firstWhere((value) => value.id == id, orElse: () => tona);
}

class Tona {
  final int angka;
  final int oktafRelatif;

  const Tona({required this.angka, this.oktafRelatif = 0})
    : assert(angka >= 1 && angka <= 5);

  String get solfeg {
    return switch (angka) {
      1 => 'da',
      2 => 'mi',
      3 => 'na',
      4 => 'ti',
      5 => 'la',
      _ => throw StateError('Angka tona di luar rentang'),
    };
  }

  String tampil(ModeNotasi mode) {
    if (mode == ModeNotasi.solfeg) return solfeg;
    return notasiAngka;
  }

  String get notasiAngka {
    if (oktafRelatif == 0) return '$angka';
    final dots = List.filled(oktafRelatif.abs(), '.').join();
    // Konvensi Sunda: oktaf rendah titik di atas, oktaf tinggi titik di bawah.
    if (oktafRelatif < 0) return '$dots\n$angka';
    return '$angka\n$dots';
  }

  Map<String, Object?> toJson() => {
    'angka': angka,
    'oktafRelatif': oktafRelatif,
  };

  static Tona fromJson(Map<String, Object?> json) {
    return Tona(
      angka: (json['angka'] as num).toInt(),
      oktafRelatif: ((json['oktafRelatif'] ?? json['oktaf'] ?? 0) as num)
          .toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Tona &&
        other.angka == angka &&
        other.oktafRelatif == oktafRelatif;
  }

  @override
  int get hashCode => Object.hash(angka, oktafRelatif);
}

class TonaTuning {
  final int angka;
  final String nama;
  final double cents;
  final double? hzTabel;

  const TonaTuning({
    required this.angka,
    required this.nama,
    required this.cents,
    this.hzTabel,
  });

  Map<String, Object?> toJson() => {
    'angka': angka,
    'nama': nama,
    'cents': cents,
    if (hzTabel != null) 'hzTabel': hzTabel,
  };

  static TonaTuning fromJson(Map<String, Object?> json) {
    return TonaTuning(
      angka: (json['angka'] as num).toInt(),
      nama: json['nama'] as String,
      cents: (json['cents'] as num).toDouble(),
      hzTabel: (json['hzTabel'] as num?)?.toDouble(),
    );
  }
}

class ProfilTuning {
  final String id;
  final String nama;
  final Laras laras;
  final String nadaDasar;
  final double frekuensiNadaDasarHz;
  final double frekuensiSampleAcuanHz;
  final List<int> urutanMenurunAngka;
  final List<TonaTuning> tonaTengah;
  final String catatan;

  const ProfilTuning({
    required this.id,
    required this.nama,
    required this.laras,
    required this.nadaDasar,
    required this.frekuensiNadaDasarHz,
    required this.frekuensiSampleAcuanHz,
    required this.urutanMenurunAngka,
    required this.tonaTengah,
    this.catatan = '',
  });

  TonaTuning entryFor(int angka) {
    return tonaTengah.firstWhere(
      (entry) => entry.angka == angka,
      orElse: () => throw ArgumentError('Tona $angka tidak ada di profil $id'),
    );
  }

  List<Tona> tangga(ArahTangga arah) {
    final angka = arah == ArahTangga.menurun
        ? urutanMenurunAngka
        : urutanMenurunAngka.reversed.toList();
    return [for (final value in angka) Tona(angka: value)];
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'nama': nama,
    'laras': laras.id,
    'nadaDasar': nadaDasar,
    'frekuensiNadaDasarHz': frekuensiNadaDasarHz,
    'frekuensiSampleAcuanHz': frekuensiSampleAcuanHz,
    'urutanMenurunAngka': urutanMenurunAngka,
    'tonaTengah': [for (final entry in tonaTengah) entry.toJson()],
    'catatan': catatan,
  };

  static ProfilTuning fromJson(Map<String, Object?> json) {
    return ProfilTuning(
      id: json['id'] as String,
      nama: json['nama'] as String,
      laras: Laras.fromId(json['laras'] as String),
      nadaDasar: json['nadaDasar'] as String,
      frekuensiNadaDasarHz: (json['frekuensiNadaDasarHz'] as num).toDouble(),
      frekuensiSampleAcuanHz: ((json['frekuensiSampleAcuanHz'] ?? 440) as num)
          .toDouble(),
      urutanMenurunAngka: [
        for (final item in json['urutanMenurunAngka'] as List)
          (item as num).toInt(),
      ],
      tonaTengah: [
        for (final item in json['tonaTengah'] as List)
          TonaTuning.fromJson(Map<String, Object?>.from(item as Map)),
      ],
      catatan: (json['catatan'] ?? '') as String,
    );
  }
}

class AturanSkoring {
  final int skorPenuh;
  final int skorUlang;

  const AturanSkoring({this.skorPenuh = 100, this.skorUlang = 60});

  int skorUntukPercobaan(int percobaan, bool benar) {
    if (!benar) return 0;
    return percobaan <= 1 ? skorPenuh : skorUlang;
  }

  Map<String, Object?> toJson() => {
    'skorPenuh': skorPenuh,
    'skorUlang': skorUlang,
  };

  static AturanSkoring fromJson(Map<String, Object?>? json) {
    if (json == null) return const AturanSkoring();
    return AturanSkoring(
      skorPenuh: ((json['skorPenuh'] ?? 100) as num).toInt(),
      skorUlang: ((json['skorUlang'] ?? 60) as num).toInt(),
    );
  }
}

class KonfigLoop {
  final bool acuanAktif;
  final JenisAcuan jenisAcuan;
  final ArahTangga arahTangga;
  final Tona? tonaPatokan;
  final List<Tona> polaContoh;
  final PolaIrama? polaIramaAcuan;
  final ModePutarAcuan modePutarAcuan;
  final bool bolehLewatiAcuan;
  final int? batasPemutaranUlang;
  final ModeInput modeInput;
  final bool bolehPercobaanUlang;
  final Duration jedaAcuanStimulus;
  final AturanSkoring skoring;

  const KonfigLoop({
    required this.acuanAktif,
    required this.jenisAcuan,
    required this.arahTangga,
    this.tonaPatokan,
    this.polaContoh = const [],
    this.polaIramaAcuan,
    required this.modePutarAcuan,
    required this.bolehLewatiAcuan,
    this.batasPemutaranUlang,
    required this.modeInput,
    required this.bolehPercobaanUlang,
    this.jedaAcuanStimulus = const Duration(milliseconds: 450),
    this.skoring = const AturanSkoring(),
  });

  Map<String, Object?> toJson() => {
    'acuanAktif': acuanAktif,
    'jenisAcuan': jenisAcuan.id,
    'arahTangga': arahTangga.id,
    if (tonaPatokan != null) 'tonaPatokan': tonaPatokan!.toJson(),
    'polaContoh': [for (final tona in polaContoh) tona.toJson()],
    if (polaIramaAcuan != null) 'polaIramaAcuan': polaIramaAcuan!.toJson(),
    'modePutarAcuan': modePutarAcuan.id,
    'bolehLewatiAcuan': bolehLewatiAcuan,
    if (batasPemutaranUlang != null) 'batasPemutaranUlang': batasPemutaranUlang,
    'modeInput': modeInput.id,
    'bolehPercobaanUlang': bolehPercobaanUlang,
    'jedaAcuanStimulusMs': jedaAcuanStimulus.inMilliseconds,
    'skoring': skoring.toJson(),
  };

  static KonfigLoop fromJson(Map<String, Object?> json) {
    return KonfigLoop(
      acuanAktif: (json['acuanAktif'] ?? true) as bool,
      jenisAcuan: JenisAcuan.fromId(
        (json['jenisAcuan'] ?? 'tangga_nada') as String,
      ),
      arahTangga: ArahTangga.fromId(
        (json['arahTangga'] ?? 'menurun') as String,
      ),
      tonaPatokan: json['tonaPatokan'] == null
          ? null
          : Tona.fromJson(
              Map<String, Object?>.from(json['tonaPatokan'] as Map),
            ),
      polaContoh: [
        for (final item in (json['polaContoh'] ?? const []) as List)
          Tona.fromJson(Map<String, Object?>.from(item as Map)),
      ],
      polaIramaAcuan: json['polaIramaAcuan'] == null
          ? null
          : PolaIrama.fromJson(
              Map<String, Object?>.from(json['polaIramaAcuan'] as Map),
            ),
      modePutarAcuan: ModePutarAcuan.fromId(
        (json['modePutarAcuan'] ?? 'otomatis') as String,
      ),
      bolehLewatiAcuan: (json['bolehLewatiAcuan'] ?? true) as bool,
      batasPemutaranUlang: (json['batasPemutaranUlang'] as num?)?.toInt(),
      modeInput: ModeInput.fromId(
        (json['modeInput'] ?? 'pilih_opsi') as String,
      ),
      bolehPercobaanUlang: (json['bolehPercobaanUlang'] ?? true) as bool,
      jedaAcuanStimulus: Duration(
        milliseconds: ((json['jedaAcuanStimulusMs'] ?? 450) as num).toInt(),
      ),
      skoring: AturanSkoring.fromJson(
        json['skoring'] == null
            ? null
            : Map<String, Object?>.from(json['skoring'] as Map),
      ),
    );
  }
}

class Ketukan {
  final double beat;
  final int angka;

  const Ketukan({required this.beat, required this.angka});

  Map<String, Object?> toJson() => {'beat': beat, 'angka': angka};

  static Ketukan fromJson(Map<String, Object?> json) {
    return Ketukan(
      beat: (json['beat'] as num).toDouble(),
      angka: (json['angka'] as num).toInt(),
    );
  }
}

class PolaIrama {
  final double tempoBpm;
  final List<Ketukan> ketukan;

  const PolaIrama({required this.tempoBpm, required this.ketukan});

  Map<String, Object?> toJson() => {
    'tempoBpm': tempoBpm,
    'ketukan': [for (final item in ketukan) item.toJson()],
  };

  static PolaIrama fromJson(Map<String, Object?> json) {
    return PolaIrama(
      tempoBpm: (json['tempoBpm'] as num).toDouble(),
      ketukan: [
        for (final item in json['ketukan'] as List)
          Ketukan.fromJson(Map<String, Object?>.from(item as Map)),
      ],
    );
  }
}

class Stimulus {
  final JenisStimulus jenis;
  final Tona? tona;
  final List<Tona> urutanTona;
  final PolaIrama? polaIrama;
  final Laras? laras;

  const Stimulus.tona(this.tona)
    : jenis = JenisStimulus.tona,
      urutanTona = const [],
      polaIrama = null,
      laras = null;

  const Stimulus.urutan(this.urutanTona)
    : jenis = JenisStimulus.urutanTona,
      tona = null,
      polaIrama = null,
      laras = null;

  const Stimulus.irama(this.polaIrama)
    : jenis = JenisStimulus.polaIrama,
      tona = null,
      urutanTona = const [],
      laras = null;

  const Stimulus.laras(this.laras)
    : jenis = JenisStimulus.laras,
      tona = null,
      urutanTona = const [],
      polaIrama = null;

  Object jawabanKanonik() {
    return switch (jenis) {
      JenisStimulus.tona => tona!.angka.toString(),
      JenisStimulus.urutanTona => [
        for (final item in urutanTona) item.angka.toString(),
      ].join('-'),
      JenisStimulus.polaIrama => 'ketuk',
      JenisStimulus.laras => laras!.id,
    };
  }

  Map<String, Object?> toJson() => {
    'jenis': jenis.id,
    if (tona != null) 'tona': tona!.toJson(),
    if (urutanTona.isNotEmpty)
      'urutanTona': [for (final item in urutanTona) item.toJson()],
    if (polaIrama != null) 'polaIrama': polaIrama!.toJson(),
    if (laras != null) 'laras': laras!.id,
  };

  static Stimulus fromJson(Map<String, Object?> json) {
    final jenis = JenisStimulus.fromId(json['jenis'] as String);
    return switch (jenis) {
      JenisStimulus.tona => Stimulus.tona(
        Tona.fromJson(Map<String, Object?>.from(json['tona'] as Map)),
      ),
      JenisStimulus.urutanTona => Stimulus.urutan([
        for (final item in json['urutanTona'] as List)
          Tona.fromJson(Map<String, Object?>.from(item as Map)),
      ]),
      JenisStimulus.polaIrama => Stimulus.irama(
        PolaIrama.fromJson(Map<String, Object?>.from(json['polaIrama'] as Map)),
      ),
      JenisStimulus.laras => Stimulus.laras(
        Laras.fromId(json['laras'] as String),
      ),
    };
  }
}

class OpsiJawaban {
  final String label;
  final String nilai;

  const OpsiJawaban({required this.label, required this.nilai});

  Map<String, Object?> toJson() => {'label': label, 'nilai': nilai};

  static OpsiJawaban fromJson(Map<String, Object?> json) {
    return OpsiJawaban(
      label: json['label'] as String,
      nilai: json['nilai'] as String,
    );
  }
}

class Soal {
  final String id;
  final String prompt;
  final Stimulus stimulus;
  final String kunciJawaban;
  final List<OpsiJawaban> pilihan;

  const Soal({
    required this.id,
    required this.prompt,
    required this.stimulus,
    required this.kunciJawaban,
    this.pilihan = const [],
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'prompt': prompt,
    'stimulus': stimulus.toJson(),
    'kunciJawaban': kunciJawaban,
    'pilihan': [for (final item in pilihan) item.toJson()],
  };

  static Soal fromJson(Map<String, Object?> json) {
    return Soal(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      stimulus: Stimulus.fromJson(
        Map<String, Object?>.from(json['stimulus'] as Map),
      ),
      kunciJawaban: (json['kunciJawaban'] ?? '') as String,
      pilihan: [
        for (final item in (json['pilihan'] ?? const []) as List)
          OpsiJawaban.fromJson(Map<String, Object?>.from(item as Map)),
      ],
    );
  }
}

class Latihan {
  final String id;
  final String judul;
  final JenisLatihan jenis;
  final KonfigLoop konfigLoop;
  final List<Soal> soal;

  const Latihan({
    required this.id,
    required this.judul,
    required this.jenis,
    required this.konfigLoop,
    required this.soal,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'judul': judul,
    'jenis': jenis.id,
    'konfigLoop': konfigLoop.toJson(),
    'soal': [for (final item in soal) item.toJson()],
  };

  static Latihan fromJson(Map<String, Object?> json) {
    return Latihan(
      id: json['id'] as String,
      judul: json['judul'] as String,
      jenis: JenisLatihan.fromId(json['jenis'] as String),
      konfigLoop: KonfigLoop.fromJson(
        Map<String, Object?>.from(json['konfigLoop'] as Map),
      ),
      soal: [
        for (final item in json['soal'] as List)
          Soal.fromJson(Map<String, Object?>.from(item as Map)),
      ],
    );
  }
}

class KriteriaPenyelesaian {
  final int minimalSesi;
  final int minimalSkor;

  const KriteriaPenyelesaian({this.minimalSesi = 1, this.minimalSkor = 60});

  Map<String, Object?> toJson() => {
    'minimalSesi': minimalSesi,
    'minimalSkor': minimalSkor,
  };

  static KriteriaPenyelesaian fromJson(Map<String, Object?> json) {
    return KriteriaPenyelesaian(
      minimalSesi: ((json['minimalSesi'] ?? 1) as num).toInt(),
      minimalSkor: ((json['minimalSkor'] ?? 60) as num).toInt(),
    );
  }
}

class Bab {
  final String id;
  final String judul;
  final String tujuan;
  final List<String> prasyaratBabId;
  final KriteriaPenyelesaian kriteria;
  final List<Latihan> latihan;

  const Bab({
    required this.id,
    required this.judul,
    required this.tujuan,
    this.prasyaratBabId = const [],
    required this.kriteria,
    required this.latihan,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'judul': judul,
    'tujuan': tujuan,
    'prasyaratBabId': prasyaratBabId,
    'kriteria': kriteria.toJson(),
    'latihan': [for (final item in latihan) item.toJson()],
  };

  static Bab fromJson(Map<String, Object?> json) {
    return Bab(
      id: json['id'] as String,
      judul: json['judul'] as String,
      tujuan: json['tujuan'] as String,
      prasyaratBabId: [
        for (final item in (json['prasyaratBabId'] ?? const []) as List)
          item as String,
      ],
      kriteria: KriteriaPenyelesaian.fromJson(
        Map<String, Object?>.from(json['kriteria'] as Map),
      ),
      latihan: [
        for (final item in json['latihan'] as List)
          Latihan.fromJson(Map<String, Object?>.from(item as Map)),
      ],
    );
  }
}

class UnitBelajar {
  final String id;
  final String judul;
  final Laras laras;
  final List<Bab> bab;

  const UnitBelajar({
    required this.id,
    required this.judul,
    required this.laras,
    required this.bab,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'judul': judul,
    'laras': laras.id,
    'bab': [for (final item in bab) item.toJson()],
  };

  static UnitBelajar fromJson(Map<String, Object?> json) {
    return UnitBelajar(
      id: json['id'] as String,
      judul: json['judul'] as String,
      laras: Laras.fromId(json['laras'] as String),
      bab: [
        for (final item in json['bab'] as List)
          Bab.fromJson(Map<String, Object?>.from(item as Map)),
      ],
    );
  }
}

class HasilSesi {
  final String latihanId;
  final String babId;
  final int benar;
  final int total;
  final int skor;
  final DateTime waktu;

  const HasilSesi({
    required this.latihanId,
    required this.babId,
    required this.benar,
    required this.total,
    required this.skor,
    required this.waktu,
  });

  Map<String, Object?> toJson() => {
    'latihanId': latihanId,
    'babId': babId,
    'benar': benar,
    'total': total,
    'skor': skor,
    'waktu': waktu.toIso8601String(),
  };

  static HasilSesi fromJson(Map<String, Object?> json) {
    return HasilSesi(
      latihanId: json['latihanId'] as String,
      babId: json['babId'] as String? ?? '',
      benar: (json['benar'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      skor: (json['skor'] as num).toInt(),
      waktu:
          DateTime.tryParse(json['waktu'] as String? ?? '') ?? DateTime(2000),
    );
  }
}

/// Statistik satu game adaptif.
class StatGame {
  final int levelTertinggi;
  final int streakTerbaik;
  final int levelAktif;
  final int streakAktif;
  final int missStreakAktif;
  final int totalRonde;
  final int totalBenar;
  final int totalSkor;
  final Map<String, int> aktivitasHarian;
  final DateTime? terakhirDimainkan;

  const StatGame({
    this.levelTertinggi = 1,
    this.streakTerbaik = 0,
    this.levelAktif = 1,
    this.streakAktif = 0,
    this.missStreakAktif = 0,
    this.totalRonde = 0,
    this.totalBenar = 0,
    this.totalSkor = 0,
    this.aktivitasHarian = const {},
    this.terakhirDimainkan,
  });

  int get rataRataSkor =>
      totalRonde == 0 ? 0 : (totalSkor / totalRonde).round();

  int get akurasiPersen =>
      totalRonde == 0 ? 0 : (totalBenar * 100 / totalRonde).round();

  StatGame catat({
    required int level,
    required int streak,
    required int missStreak,
    required int skor,
    required bool benar,
    bool simpanLevelAktif = true,
    DateTime? waktu,
  }) {
    final when = waktu ?? DateTime.now();
    final hari = _tanggalKey(when);
    return StatGame(
      levelTertinggi: level > levelTertinggi ? level : levelTertinggi,
      streakTerbaik: streak > streakTerbaik ? streak : streakTerbaik,
      levelAktif: simpanLevelAktif ? level : levelAktif,
      streakAktif: simpanLevelAktif ? streak : streakAktif,
      missStreakAktif: simpanLevelAktif ? missStreak : missStreakAktif,
      totalRonde: totalRonde + 1,
      totalBenar: totalBenar + (benar ? 1 : 0),
      totalSkor: totalSkor + skor.clamp(0, 100),
      aktivitasHarian: {
        ...aktivitasHarian,
        hari: (aktivitasHarian[hari] ?? 0) + 1,
      },
      terakhirDimainkan: when,
    );
  }

  Map<String, Object?> toJson() => {
    'levelTertinggi': levelTertinggi,
    'streakTerbaik': streakTerbaik,
    'levelAktif': levelAktif,
    'streakAktif': streakAktif,
    'missStreakAktif': missStreakAktif,
    'totalRonde': totalRonde,
    'totalBenar': totalBenar,
    'totalSkor': totalSkor,
    'aktivitasHarian': aktivitasHarian,
    if (terakhirDimainkan != null)
      'terakhirDimainkan': terakhirDimainkan!.toIso8601String(),
  };

  static StatGame fromJson(Map<String, Object?> json) => StatGame(
    levelTertinggi: ((json['levelTertinggi'] ?? 1) as num).toInt(),
    streakTerbaik: ((json['streakTerbaik'] ?? 0) as num).toInt(),
    levelAktif: ((json['levelAktif'] ?? json['levelTertinggi'] ?? 1) as num)
        .toInt(),
    streakAktif: ((json['streakAktif'] ?? 0) as num).toInt(),
    missStreakAktif: ((json['missStreakAktif'] ?? 0) as num).toInt(),
    totalRonde: ((json['totalRonde'] ?? 0) as num).toInt(),
    totalBenar: ((json['totalBenar'] ?? 0) as num).toInt(),
    totalSkor: ((json['totalSkor'] ?? 0) as num).toInt(),
    aktivitasHarian: {
      for (final e in ((json['aktivitasHarian'] ?? const {}) as Map).entries)
        e.key as String: (e.value as num).toInt(),
    },
    terakhirDimainkan: DateTime.tryParse(
      json['terakhirDimainkan'] as String? ?? '',
    ),
  );
}

String _tanggalKey(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}

/// Progres pengguna: statistik per-game (model berbasis game generatif).
class ProgresPengguna {
  final Map<String, StatGame> game;
  final bool tidakDapatDipulihkan;

  const ProgresPengguna({
    this.game = const {},
    this.tidakDapatDipulihkan = false,
  });

  factory ProgresPengguna.kosong({bool rusak = false}) {
    return ProgresPengguna(tidakDapatDipulihkan: rusak);
  }

  int get totalRonde =>
      game.values.fold(0, (jumlah, stat) => jumlah + stat.totalRonde);

  ProgresPengguna copyWith({
    Map<String, StatGame>? game,
    bool? tidakDapatDipulihkan,
  }) {
    return ProgresPengguna(
      game: game ?? this.game,
      tidakDapatDipulihkan: tidakDapatDipulihkan ?? this.tidakDapatDipulihkan,
    );
  }

  ProgresPengguna catatRonde(
    String gameId, {
    required int level,
    required int streak,
    required int missStreak,
    required int skor,
    required bool benar,
    bool simpanLevelAktif = true,
    DateTime? waktu,
  }) {
    final lama = game[gameId] ?? const StatGame();
    return copyWith(
      game: {
        ...game,
        gameId: lama.catat(
          level: level,
          streak: streak,
          missStreak: missStreak,
          skor: skor,
          benar: benar,
          simpanLevelAktif: simpanLevelAktif,
          waktu: waktu,
        ),
      },
    );
  }

  Map<String, Object?> toJson() => {
    'game': {for (final e in game.entries) e.key: e.value.toJson()},
  };

  static ProgresPengguna fromJson(Map<String, Object?> json) {
    final raw = (json['game'] ?? const <String, Object?>{}) as Map;
    return ProgresPengguna(
      game: {
        for (final e in raw.entries)
          e.key as String: StatGame.fromJson(
            Map<String, Object?>.from(e.value as Map),
          ),
      },
    );
  }
}

class Pengaturan {
  final String profilTuningId;
  final ModeNotasi modeNotasi;
  final bool acuanOtomatis;
  final ModeTema tema;
  final double toleransiCents;
  final PilihanInstrumen instrumen;
  final Artikulasi artikulasi;

  const Pengaturan({
    required this.profilTuningId,
    required this.modeNotasi,
    required this.acuanOtomatis,
    required this.tema,
    required this.toleransiCents,
    required this.instrumen,
    required this.artikulasi,
  });

  factory Pengaturan.bawaan() {
    return const Pengaturan(
      profilTuningId: 'salendro',
      modeNotasi: ModeNotasi.angka,
      acuanOtomatis: true,
      tema: ModeTema.terang,
      toleransiCents: 50,
      instrumen: PilihanInstrumen.auto,
      artikulasi: Artikulasi.muka,
    );
  }

  Pengaturan copyWith({
    String? profilTuningId,
    ModeNotasi? modeNotasi,
    bool? acuanOtomatis,
    ModeTema? tema,
    double? toleransiCents,
    PilihanInstrumen? instrumen,
    Artikulasi? artikulasi,
  }) {
    return Pengaturan(
      profilTuningId: profilTuningId ?? this.profilTuningId,
      modeNotasi: modeNotasi ?? this.modeNotasi,
      acuanOtomatis: acuanOtomatis ?? this.acuanOtomatis,
      tema: tema ?? this.tema,
      toleransiCents: toleransiCents ?? this.toleransiCents,
      instrumen: instrumen ?? this.instrumen,
      artikulasi: artikulasi ?? this.artikulasi,
    );
  }

  Map<String, Object?> toJson() => {
    'profilTuningId': profilTuningId,
    'modeNotasi': modeNotasi.id,
    'acuanOtomatis': acuanOtomatis,
    'tema': tema.id,
    'toleransiCents': toleransiCents,
    'instrumen': instrumen.id,
    'artikulasi': artikulasi.id,
  };

  static Pengaturan fromJson(Map<String, Object?> json) {
    final fallback = Pengaturan.bawaan();
    double rangeDouble(String key, double min, double max, double def) {
      final value = (json[key] as num?)?.toDouble();
      if (value == null || value < min || value > max) return def;
      return value;
    }

    final profil = json['profilTuningId'] as String? ?? fallback.profilTuningId;
    return Pengaturan(
      profilTuningId: profil.isEmpty ? fallback.profilTuningId : profil,
      modeNotasi: ModeNotasi.angka,
      acuanOtomatis: json['acuanOtomatis'] as bool? ?? fallback.acuanOtomatis,
      tema: ModeTema.fromId(json['tema'] as String? ?? 'terang'),
      toleransiCents: rangeDouble(
        'toleransiCents',
        5,
        120,
        fallback.toleransiCents,
      ),
      instrumen: PilihanInstrumen.fromId(
        json['instrumen'] as String? ?? fallback.instrumen.id,
      ),
      artikulasi: Artikulasi.fromId(
        json['artikulasi'] as String? ?? fallback.artikulasi.id,
      ),
    );
  }

  static Pengaturan fromJsonString(String raw) {
    return fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map));
  }
}

/// Jenis simbol tertulis pada notasi angka (jianpu Sunda) untuk game melodi.
enum JenisSimbol { nada, istirahat, perpanjangan }

/// Satu simbol dalam deret notasi angka.
///
/// - [JenisSimbol.nada]: angka 1..5 dengan [oktafRelatif] dan [beam].
/// - [JenisSimbol.istirahat]: ditulis `0`, bisa ber-[beam].
/// - [JenisSimbol.perpanjangan]: ditulis `.`, menambah 50% durasi simbol
///   bunyi/istirahat sebelumnya (titik augmentasi).
///
/// [beam] = jumlah garis durasi (digambar di atas, konvensi Sunda):
/// 0 = seperempat (1 ketuk), 1 = seperdelapan (½), 2 = seperenambelas (¼).
class SimbolNot {
  final JenisSimbol jenis;
  final int angka;
  final int oktafRelatif;
  final int beam;

  const SimbolNot.nada(this.angka, {this.oktafRelatif = 0, this.beam = 0})
    : jenis = JenisSimbol.nada,
      assert(angka >= 1 && angka <= 5);

  const SimbolNot.istirahat({this.beam = 0})
    : jenis = JenisSimbol.istirahat,
      angka = 0,
      oktafRelatif = 0;

  const SimbolNot.perpanjangan()
    : jenis = JenisSimbol.perpanjangan,
      angka = 0,
      oktafRelatif = 0,
      beam = 0;

  Tona? get tona => jenis == JenisSimbol.nada
      ? Tona(angka: angka, oktafRelatif: oktafRelatif)
      : null;

  SimbolNot copyWith({int? angka, int? oktafRelatif, int? beam}) {
    switch (jenis) {
      case JenisSimbol.nada:
        return SimbolNot.nada(
          angka ?? this.angka,
          oktafRelatif: oktafRelatif ?? this.oktafRelatif,
          beam: beam ?? this.beam,
        );
      case JenisSimbol.istirahat:
        return SimbolNot.istirahat(beam: beam ?? this.beam);
      case JenisSimbol.perpanjangan:
        return const SimbolNot.perpanjangan();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SimbolNot &&
      other.jenis == jenis &&
      other.angka == angka &&
      other.oktafRelatif == oktafRelatif &&
      other.beam == beam;

  @override
  int get hashCode => Object.hash(jenis, angka, oktafRelatif, beam);

  @override
  String toString() => switch (jenis) {
    JenisSimbol.nada => 'nada($angka,okt$oktafRelatif,beam$beam)',
    JenisSimbol.istirahat => 'istirahat(beam$beam)',
    JenisSimbol.perpanjangan => 'perpanjangan',
  };
}

/// Kejadian audio yang siap diputar: satu nada (atau istirahat bila [tona]
/// null) dengan durasi [ketuk] dalam satuan ketukan.
class KejadianMelodi {
  final Tona? tona;
  final double ketuk;

  const KejadianMelodi({required this.tona, required this.ketuk});
}

/// Urutan nada acuan standar (palindrom, mulai & berakhir di da):
/// da mi na ti la ti na mi da — turun lalu naik kembali ke da.
List<Tona> nadaAcuan() => const [
  Tona(angka: 1),
  Tona(angka: 2),
  Tona(angka: 3),
  Tona(angka: 4),
  Tona(angka: 5),
  Tona(angka: 4),
  Tona(angka: 3),
  Tona(angka: 2),
  Tona(angka: 1),
];
