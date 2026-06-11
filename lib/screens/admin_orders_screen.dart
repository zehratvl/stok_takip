import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  Future<void> _onayla(BuildContext context, DocumentSnapshot doc) async {
    final firestore = FirebaseFirestore.instance;
    final t = doc.data() as Map<String, dynamic>;
    final miktar = t['miktar'] ?? 0;
    final urunId = t['urunId'];

    await firestore.runTransaction((transaction) async {
      final urunRef = firestore.collection('products').doc(urunId);
      final urunSnap = await transaction.get(urunRef);
      final mevcutStok = (urunSnap.data() as Map<String, dynamic>?)?['stok'] ?? 0;
      transaction.update(urunRef, {'stok': mevcutStok + miktar});
      transaction.update(doc.reference, {'durum': 'onaylandi'});
    });

    await firestore.collection('stockMovements').add({
      'urunId': urunId,
      'urunIsim': t['urunIsim'],
      'tip': 'giris',
      'miktar': miktar,
      'not': 'Sipariş talebi onaylandı',
      'kullanici': 'Admin',
      'tarih': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _reddet(DocumentSnapshot doc) async {
    await FirebaseFirestore.instance.collection('orders').doc(doc.id).update({'durum': 'reddedildi'});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist_rounded, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 8),
              Text('Sipariş Talepleri', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Çalışanların stok taleplerini onaylayın veya reddedin.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders').orderBy('tarih', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final talepler = snapshot.data?.docs ?? [];
                  if (talepler.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.checklist_outlined, size: 48, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 8),
                          Text('Henüz talep yok', style: TextStyle(color: Color(0xFF94A3B8))),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('Ürün', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                            Expanded(flex: 1, child: Text('Miktar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                            Expanded(flex: 2, child: Text('Talep Eden', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                            Expanded(flex: 2, child: Text('Durum', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                            Expanded(flex: 2, child: Text('İşlem', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: talepler.length,
                          itemBuilder: (context, index) {
                            final doc = talepler[index];
                            final t = doc.data() as Map<String, dynamic>;
                            final durum = t['durum'] ?? 'beklemede';
                            Color durumRenk = const Color(0xFFD97706);
                            Color durumBg = const Color(0xFFFFFBEB);
                            String durumText = 'Beklemede';
                            if (durum == 'onaylandi') {
                              durumRenk = const Color(0xFF059669);
                              durumBg = const Color(0xFFDCFCE7);
                              durumText = 'Onaylandı';
                            } else if (durum == 'reddedildi') {
                              durumRenk = const Color(0xFFDC2626);
                              durumBg = const Color(0xFFFEE2E2);
                              durumText = 'Reddedildi';
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                              child: Row(
                                children: [
                                  Expanded(flex: 3, child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t['urunIsim'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                                      if ((t['not'] ?? '').isNotEmpty)
                                        Text(t['not'], style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                    ],
                                  )),
                                  Expanded(flex: 1, child: Text('${t['miktar']}', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                                  Expanded(flex: 2, child: Text(t['talepEden'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: durumBg, borderRadius: BorderRadius.circular(6)),
                                      child: Text(durumText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: durumRenk)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: durum == 'beklemede'
                                        ? Row(
                                            children: [
                                              ElevatedButton(
                                                onPressed: () => _onayla(context, doc),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF059669),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  minimumSize: Size.zero,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                ),
                                                child: const Text('Onayla', style: TextStyle(fontSize: 11)),
                                              ),
                                              const SizedBox(width: 6),
                                              ElevatedButton(
                                                onPressed: () => _reddet(doc),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFDC2626),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  minimumSize: Size.zero,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                ),
                                                child: const Text('Reddet', style: TextStyle(fontSize: 11)),
                                              ),
                                            ],
                                          )
                                        : const SizedBox(),
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
}