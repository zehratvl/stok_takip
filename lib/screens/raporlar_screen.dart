import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class RaporlarScreen extends StatefulWidget {
  final String? baslangicUrunId;
  final String? baslangicUrunIsim;

  const RaporlarScreen({
    super.key,
    this.baslangicUrunId,
    this.baslangicUrunIsim,
  });

  @override
  State<RaporlarScreen> createState() => _RaporlarScreenState();
}

class _RaporlarScreenState extends State<RaporlarScreen> {
  final _firestore = FirebaseFirestore.instance;

  String? _seciliUrunId;
  String? _seciliUrunIsim;

  List<Map<String, dynamic>> _urunler = [];
  List<Map<String, dynamic>> _hareketler = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    if (widget.baslangicUrunId != null) {
      _seciliUrunId = widget.baslangicUrunId;
      _seciliUrunIsim = widget.baslangicUrunIsim;
    }
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);

    final urunSnap = await _firestore.collection('products').get();
    final urunler = urunSnap.docs.map((d) {
      final data = d.data();
      return {
        'id': d.id,
        'isim': data['isim'] ?? '',
        'alisFiyat': (data['alisFiyat'] ?? 0).toDouble(),
        'fiyat': (data['fiyat'] ?? 0).toDouble(),
      };
    }).toList();

    final hareketSnap = await _firestore.collection('stockMovements').get();

    final hareketler = hareketSnap.docs
        .map((d) {
          final data = d.data();
          return {
            'urunId': data['urunId'] ?? '',
            'urunIsim': data['urunIsim'] ?? '',
            'tip': data['tip'] ?? '',
            'miktar': (data['miktar'] ?? 0) as num,
            'tarih': (data['tarih'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        })
        .where((h) => h['tip'] == 'cikis')
        .toList();

    hareketler.sort((a, b) =>
        (a['tarih'] as DateTime).compareTo(b['tarih'] as DateTime));

    setState(() {
      _urunler = urunler;
      _hareketler = hareketler;
      _yukleniyor = false;
    });
  }

  List<Map<String, dynamic>> get _filtreliHareketler {
    if (_seciliUrunId == null) return _hareketler;
    return _hareketler.where((h) => h['urunId'] == _seciliUrunId).toList();
  }

  Map<String, dynamic> _urunBul(String urunId) {
    return _urunler.firstWhere(
      (u) => u['id'] == urunId,
      orElse: () => {'alisFiyat': 0.0, 'fiyat': 0.0},
    );
  }

  double get _toplamCiro {
    return _filtreliHareketler.fold(0.0, (t, h) {
      final urun = _urunBul(h['urunId']);
      return t + (urun['fiyat'] as double) * (h['miktar'] as num);
    });
  }

  double get _toplamMaliyet {
    return _filtreliHareketler.fold(0.0, (t, h) {
      final urun = _urunBul(h['urunId']);
      return t + (urun['alisFiyat'] as double) * (h['miktar'] as num);
    });
  }

  double get _netKar => _toplamCiro - _toplamMaliyet;
  double get _karOrani =>
      _toplamCiro == 0 ? 0 : (_netKar / _toplamCiro * 100);

  List<_GunlukVeri> get _gunlukVeriler {
    final bugun = DateTime.now();
    final gunler = List.generate(30, (i) {
      final gun = bugun.subtract(Duration(days: 29 - i));
      return DateTime(gun.year, gun.month, gun.day);
    });

    return gunler.map((gun) {
      final gunHareketleri = _filtreliHareketler.where((h) {
        final t = h['tarih'] as DateTime;
        return t.year == gun.year && t.month == gun.month && t.day == gun.day;
      }).toList();

      double ciro = 0, maliyet = 0;
      for (final h in gunHareketleri) {
        final urun = _urunBul(h['urunId']);
        ciro += (urun['fiyat'] as double) * (h['miktar'] as num);
        maliyet += (urun['alisFiyat'] as double) * (h['miktar'] as num);
      }

      return _GunlukVeri(tarih: gun, ciro: ciro, kar: ciro - maliyet);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    final gunluk = _gunlukVeriler;
    final maxY = gunluk.fold(0.0, (m, g) => g.ciro > m ? g.ciro : m);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Finansal Analiz',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_seciliUrunId != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_rounded,
                        color: Color(0xFF2563EB), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '"$_seciliUrunIsim" ürününe ait özel analiz verilerini görüntülüyorsunuz.',
                        style: const TextStyle(
                            color: Color(0xFF1D4ED8), fontSize: 13),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _seciliUrunId = null;
                        _seciliUrunIsim = null;
                      }),
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Filtreyi Temizle'),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          textStyle: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                const Text('Finansal Analiz',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _seciliUrunId,
                      hint: const Text('Tüm Ürünler',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF64748B))),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tüm Ürünler',
                              style: TextStyle(fontSize: 13)),
                        ),
                        ..._urunler.map((u) => DropdownMenuItem<String?>(
                              value: u['id'],
                              child: Text(u['isim'],
                                  style: const TextStyle(fontSize: 13)),
                            )),
                      ],
                      onChanged: (val) {
                        final urun = val == null
                            ? null
                            : _urunler.firstWhere((u) => u['id'] == val);
                        setState(() {
                          _seciliUrunId = val;
                          _seciliUrunIsim = urun?['isim'];
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                _kart(
                  baslik: 'TOPLAM CİRO (NET)',
                  deger: '₺${_toplamCiro.toStringAsFixed(2)}',
                  renk: const Color(0xFF2563EB),
                  bg: const Color(0xFFEFF6FF),
                ),
                const SizedBox(width: 16),
                _kart(
                  baslik: 'TOPLAM ÜRÜN MALİYETİ',
                  deger: '₺${_toplamMaliyet.toStringAsFixed(2)}',
                  renk: const Color(0xFFDC2626),
                  bg: const Color(0xFFFFF1F2),
                ),
                const SizedBox(width: 16),
                _kart(
                  baslik: 'NET İŞLETME KARI',
                  deger: '₺${_netKar.toStringAsFixed(2)}',
                  renk: Colors.white,
                  degerRenk: _netKar >= 0
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                  bg: const Color(0xFF1E293B),
                  baslikRenk: const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 16),
                _kart(
                  baslik: 'NET KAR ORANI',
                  deger: '% ${_karOrani.toStringAsFixed(1)}',
                  renk: const Color(0xFF059669),
                  bg: const Color(0xFFF0FDF4),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              _seciliUrunIsim != null
                  ? '${_seciliUrunIsim!.toUpperCase()} · GÜNLÜK PERFORMANS'
                  : 'TÜM ÜRÜNLER · GÜNLÜK PERFORMANS',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                _legend('Ciro ₺', const Color(0xFF2563EB)),
                const SizedBox(width: 16),
                _legend('Kar ₺', const Color(0xFF059669)),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 8)
                  ],
                ),
                child: gunluk.every((g) => g.ciro == 0)
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart_rounded,
                                size: 48, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 8),
                            Text('Henüz satış verisi yok',
                                style: TextStyle(color: Color(0xFF94A3B8))),
                          ],
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: maxY == 0 ? 10 : maxY * 1.2,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color: const Color(0xFFF1F5F9),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 48,
                                getTitlesWidget: (v, m) => Text(
                                  '₺${v.toInt()}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                interval: 5,
                                getTitlesWidget: (v, m) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= gunluk.length) {
                                    return const SizedBox();
                                  }
                                  final t = gunluk[i].tarih;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${t.day.toString().padLeft(2, '0')} ${_ayKisa(t.month)}',
                                      style: const TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFF94A3B8)),
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: gunluk.asMap().entries.map((e) {
                                return FlSpot(
                                    e.key.toDouble(), e.value.ciro);
                              }).toList(),
                              isCurved: true,
                              color: const Color(0xFF2563EB),
                              barWidth: 2,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, pct, bar, idx) =>
                                    FlDotCirclePainter(
                                  radius: spot.y == 0 ? 2 : 4,
                                  color: const Color(0xFF2563EB),
                                  strokeWidth: 0,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF2563EB).withOpacity(0.08),
                              ),
                            ),
                            LineChartBarData(
                              spots: gunluk.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(),
                                    e.value.kar < 0 ? 0 : e.value.kar);
                              }).toList(),
                              isCurved: true,
                              color: const Color(0xFF059669),
                              barWidth: 2,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, pct, bar, idx) =>
                                    FlDotCirclePainter(
                                  radius: spot.y == 0 ? 2 : 4,
                                  color: const Color(0xFF059669),
                                  strokeWidth: 0,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF059669).withOpacity(0.08),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (spots) => spots.map((s) {
                                final label = s.barIndex == 0 ? 'Ciro' : 'Kar';
                                return LineTooltipItem(
                                  '$label: ₺${s.y.toStringAsFixed(2)}',
                                  TextStyle(
                                    color: s.barIndex == 0
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF059669),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kart({
    required String baslik,
    required String deger,
    required Color renk,
    required Color bg,
    Color? degerRenk,
    Color? baslikRenk,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              baslik,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: baslikRenk ?? const Color(0xFF64748B),
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              deger,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: degerRenk ?? renk),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(String label, Color renk) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 3,
          decoration: BoxDecoration(
            color: renk,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  String _ayKisa(int ay) {
    const aylar = [
      '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return aylar[ay];
  }
}

class _GunlukVeri {
  final DateTime tarih;
  final double ciro;
  final double kar;

  _GunlukVeri({required this.tarih, required this.ciro, required this.kar});
}