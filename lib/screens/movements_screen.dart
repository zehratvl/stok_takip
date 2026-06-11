import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.swap_vert_rounded, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 8),
              Text('Stok Hareketleri',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 8)
                ],
              ),
              child: StreamBuilder<QuerySnapshot>(
               stream: _firestore
    .collection('stockMovements')
    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var hareketler = snapshot.data?.docs ?? [];
hareketler = hareketler.toList()
  ..sort((a, b) {
    final at = (a.data() as Map<String, dynamic>)['tarih'];
    final bt = (b.data() as Map<String, dynamic>)['tarih'];
    if (at == null || bt == null) return 0;
    return (bt as Timestamp).compareTo(at as Timestamp);
  });
                  if (hareketler.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swap_vert,
                              size: 48, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 8),
                          Text('Henüz hareket yok',
                              style: TextStyle(color: Color(0xFF94A3B8))),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: const BoxDecoration(
                            border: Border(
                                bottom:
                                    BorderSide(color: Color(0xFFE2E8F0)))),
                        child: const Row(
                          children: [
                            Expanded(
                                flex: 1,
                                child: Text('Tip',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B)))),
                            Expanded(
                                flex: 3,
                                child: Text('Ürün',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B)))),
                            Expanded(
                                flex: 2,
                                child: Text('Kullanıcı',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B)))),
                            Expanded(
                                flex: 1,
                                child: Text('Miktar',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B)))),
                            Expanded(
                                flex: 2,
                                child: Text('Tarih',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B)))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: hareketler.length,
                          itemBuilder: (context, index) {
                            final h = hareketler[index].data()
                                as Map<String, dynamic>;
                            final giris = h['tip'] == 'giris';
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              decoration: const BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Color(0xFFF1F5F9)))),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: giris
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFFEE2E2),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            giris
                                                ? Icons.arrow_downward_rounded
                                                : Icons.arrow_upward_rounded,
                                            size: 12,
                                            color: giris
                                                ? const Color(0xFF059669)
                                                : const Color(0xFFDC2626),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            giris ? 'Giriş' : 'Çıkış',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: giris
                                                    ? const Color(0xFF059669)
                                                    : const Color(0xFFDC2626)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(h['urunIsim'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1E293B))),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(h['kullanici'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B))),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${giris ? '+' : '-'}${h['miktar']}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: giris
                                              ? const Color(0xFF059669)
                                              : const Color(0xFFDC2626)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(_tarihFormat(h['tarih']),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF94A3B8))),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tarihFormat(dynamic tarih) {
    if (tarih == null) return '-';
    try {
      final dt = (tarih as Timestamp).toDate();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '-';
    }
  }
}