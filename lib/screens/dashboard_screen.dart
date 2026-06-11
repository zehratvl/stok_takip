import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'products_screen.dart';
import 'movements_screen.dart';
import 'categories_screen.dart';
import '../services/user_service.dart';
import 'orders_screen.dart';
import 'admin_orders_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'sales_screen.dart';
import 'raporlar_screen.dart';
import 'dusuk_stok_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _rol = '';

@override
void initState() {
  super.initState();
  _rolGetir();
}

Future<void> _rolGetir() async {
  final rol = await UserService.kullaniciRoluGetir();
  setState(() => _rol = rol ?? 'calisan');
}

List<Widget> get _screens => [
  const _DashboardBody(),
  const ProductsScreen(),
  const SalesScreen(),
  const RaporlarScreen(),
  const DusukStokScreen(),
const CategoriesScreen(),
  if (_rol == 'admin') const AdminOrdersScreen(),
  if (_rol == 'calisan') const OrdersScreen(),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('stOK', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      actions: [

  _navItem(0, 'Genel Bakış', Icons.dashboard_rounded),
  _navItem(1, 'Ürünler', Icons.inventory_2_outlined),
  _navItem(2, 'Satış', Icons.shopping_cart_rounded),
  _navItem(3, 'Raporlar', Icons.bar_chart_rounded),
  _navItem(4, 'Düşük Stok', Icons.warning_amber_rounded),
  _navItem(5, 'Kategoriler', Icons.label_rounded),
  if (_rol == 'admin') _navItem(6, 'Siparişler', Icons.checklist_rounded),
  if (_rol == 'calisan') _navItem(6, 'Siparişlerim', Icons.shopping_cart_rounded),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF64748B)),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () async {
  final onay = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Çıkış Yap'),
      content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Vazgeç', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white),
          child: const Text('Çıkış Yap'),
        ),
      ],
    ),
  );
  if (onay == true) FirebaseAuth.instance.signOut();
},
              child: CircleAvatar(
                backgroundColor: const Color(0xFF2563EB),
                radius: 16,
                child: Text(
                  (FirebaseAuth.instance.currentUser?.email ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
    );
  }

  Widget _navItem(int index, String label, IconData icon) {
    final selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        final urunler = snapshot.data?.docs ?? [];
        final toplamUrun = urunler.length;
        final kritikUrunler = urunler.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return (data['stok'] ?? 0) <= (data['kritikSeviye'] ?? 5);
        }).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('categories').snapshots(),
          builder: (context, catSnapshot) {
            final kategoriler = catSnapshot.data?.docs ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Genel Bakış', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text('Hoşgeldin, işte dükkanının son durumu.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildKart('TOPLAM ÜRÜN', toplamUrun.toString(), Icons.inventory_2_rounded, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                      const SizedBox(width: 16),
                      _buildKart('KATEGORİLER', kategoriler.length.toString(), Icons.label_rounded, const Color(0xFF0891B2), const Color(0xFFECFEFF)),
                      const SizedBox(width: 16),
                      _buildKart('DÜŞÜK STOK', kritikUrunler.length.toString(), Icons.warning_amber_rounded, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
                      const SizedBox(width: 16),
                      StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('stockMovements')
      .where('tip', isEqualTo: 'cikis')
      .snapshots(),
  builder: (context, hareketSnap) {
    final bugun = DateTime.now();
    double gunlukSatis = 0;
    for (final doc in hareketSnap.data?.docs ?? []) {
      final h = doc.data() as Map<String, dynamic>;
      final tarih = (h['tarih'] as Timestamp?)?.toDate();
      if (tarih != null &&
          tarih.year == bugun.year &&
          tarih.month == bugun.month &&
          tarih.day == bugun.day) {
        gunlukSatis += (h['tutar'] ?? 0).toDouble();
      }
    }
    return _buildKart(
      'GÜNLÜK SATIŞ',
      '₺${gunlukSatis.toStringAsFixed(2)}',
      Icons.attach_money_rounded,
      const Color(0xFF059669),
      const Color(0xFFECFDF5),
    );
  },
),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildDusukStokTablosu(kritikUrunler)),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _buildSonEklenenler(urunler)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildKategoriGrafigi(urunler, kategoriler)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKart(String baslik, String deger, IconData icon, Color renk, Color bgRenk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: renk, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgRenk, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: renk, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(deger, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDusukStokTablosu(List<QueryDocumentSnapshot> kritikUrunler) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 8),
                    Text('Düşük Stoklu Ürünler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                  ],
                ),
                TextButton(onPressed: () {}, child: const Text('Tümünü Gör', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13))),
              ],
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                children: [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text('Ürün', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Kategori', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Stok', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                ],
              ),
              if (kritikUrunler.isEmpty)
                const TableRow(children: [
                  Padding(padding: EdgeInsets.all(20), child: Text('Düşük stoklu ürün yok 👍', style: TextStyle(color: Color(0xFF64748B), fontSize: 13))),
                  SizedBox(),
                  SizedBox(),
                ]),
              ...kritikUrunler.take(5).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final stok = data['stok'] ?? 0;
                return TableRow(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Text(data['isim'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                        child: Text(data['kategori'] ?? '-', style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('$stok adet', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSonEklenenler(List<QueryDocumentSnapshot> urunler) {
    final sonlar = urunler.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, color: Color(0xFF2563EB), size: 18),
                SizedBox(width: 8),
                Text('SON EKLENENLER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B), letterSpacing: 0.5)),
              ],
            ),
          ),
          ...sonlar.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF2563EB), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(data['isim'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                  ),
                  Text('₺${data['fiyat'] ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildKategoriGrafigi(List<QueryDocumentSnapshot> urunler, List<QueryDocumentSnapshot> kategoriler) {
    if (kategoriler.isEmpty) return const SizedBox();

    final renkler = [
      const Color(0xFF2563EB),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFF7C3AED),
      const Color(0xFF0891B2),
    ];

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < kategoriler.length; i++) {
      final katIsim = (kategoriler[i].data() as Map<String, dynamic>)['isim'] ?? '';
      final sayi = urunler.where((u) => (u.data() as Map<String, dynamic>)['kategori'] == katIsim).length;
      if (sayi > 0) {
        sections.add(PieChartSectionData(
          value: sayi.toDouble(),
          title: '$sayi',
          color: renkler[i % renkler.length],
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ));
      }
    }

    if (sections.isEmpty) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: Color(0xFF2563EB), size: 18),
              SizedBox(width: 8),
              Text('Kategori Dağılımı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                height: 200,
                width: 200,
                child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 2)),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: kategoriler.asMap().entries.map((e) {
                  final katIsim = (e.value.data() as Map<String, dynamic>)['isim'] ?? '';
                  final sayi = urunler.where((u) => (u.data() as Map<String, dynamic>)['kategori'] == katIsim).length;
                  if (sayi == 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: renkler[e.key % renkler.length], borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 8),
                        Text(katIsim, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                        const SizedBox(width: 8),
                        Text('($sayi)', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}