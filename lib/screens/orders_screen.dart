import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _firestore = FirebaseFirestore.instance;

  void _siparisOlusturDialog() {
    String? secilenUrunId;
    String? secilenUrunIsim;
    final miktarController = TextEditingController();
    final notController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sipariş Talebi Oluştur',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ürün Seç', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 6),
                  StreamBuilder(
                    stream: _firestore.collection('products').snapshots(),
                    builder: (context, snapshot) {
                      final urunler = snapshot.data?.docs ?? [];
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        hint: const Text('Ürün seçiniz...'),
                        value: secilenUrunId,
                        items: urunler.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(value: doc.id, child: Text(data['isim'] ?? ''));
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            secilenUrunId = val;
                            secilenUrunIsim = (urunler.firstWhere((d) => d.id == val).data() as Map<String, dynamic>)['isim'];
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Talep Edilen Miktar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: miktarController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Not (opsiyonel)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Color(0xFF64748B)))),
            ElevatedButton.icon(
              onPressed: () async {
                if (secilenUrunId == null || miktarController.text.isEmpty) return;
                final user = FirebaseAuth.instance.currentUser;
                await _firestore.collection('orders').add({
                  'urunId': secilenUrunId,
                  'urunIsim': secilenUrunIsim,
                  'miktar': int.tryParse(miktarController.text) ?? 0,
                  'not': notController.text,
                  'talepEden': user?.email,
                  'durum': 'beklemede',
                  'tarih': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Talebi Gönder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shopping_cart_rounded, color: Color(0xFF2563EB), size: 22),
                  SizedBox(width: 8),
                  Text('Sipariş Taleplerim', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _siparisOlusturDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Yeni Talep'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Admin onayı bekleyen talepleriniz.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('orders').where('talepEden', isEqualTo: user?.email).orderBy('tarih', descending: true).snapshots(),
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
                          Icon(Icons.shopping_cart_outlined, size: 48, color: Color(0xFFCBD5E1)),
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
                            Expanded(flex: 2, child: Text('Tarih', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                            Expanded(flex: 2, child: Text('Durum', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: talepler.length,
                          itemBuilder: (context, index) {
                            final t = talepler[index].data() as Map<String, dynamic>;
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
                                  Expanded(flex: 3, child: Text(t['urunIsim'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
                                  Expanded(flex: 1, child: Text('${t['miktar']}', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                                  Expanded(flex: 2, child: Text(_tarihFormat(t['tarih']), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: durumBg, borderRadius: BorderRadius.circular(6)),
                                      child: Text(durumText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: durumRenk)),
                                    ),
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
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (e) {
      return '-';
    }
  }
}