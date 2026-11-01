import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false,
  theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6C63FF)), scaffoldBackgroundColor: const Color(0xFFF7F8FC)),
  home: const App()));

final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final dfmt = DateFormat('dd MMM yyyy • HH:mm', 'id_ID');
const cP = Color(0xFF6C63FF), cG = Color(0xFF22C55E), cR = Color(0xFFEF4444);

class App extends StatefulWidget { const App({super.key}); @override State<App> createState() => _S(); }
class _S extends State<App> {
  List<Map> tx = [];
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final r = (await SharedPreferences.getInstance()).getString('tx');
    if (r != null) setState(() => tx = (jsonDecode(r) as List).cast<Map>()); }
  Future<void> _save() async => (await SharedPreferences.getInstance()).setString('tx', jsonEncode(tx));
  double get bal => tx.fold(0, (s, e) => s + (e['i'] == true ? e['a'] : -e['a']));

  void _add({bool income = false}) async {
    final c = TextEditingController(), a = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(income ? 'Pemasukan' : 'Pengeluaran'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c, decoration: const InputDecoration(labelText: 'Nama')),
        TextField(controller: a, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Nominal'))]),
      actions: [TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(_, true), child: const Text('Simpan'))]));
    if (ok == true && c.text.isNotEmpty) { setState(() => tx.insert(0,
      {'t': c.text, 'a': double.tryParse(a.text) ?? 0, 'i': income, 'd': DateTime.now().toIso8601String()}));
      await _save(); } c.dispose(); a.dispose();
  }

  void _struk(Map t) => showModalBottomSheet(context: context, isScrollControlled: true,
    backgroundColor: Colors.transparent, builder: (_) => _Struk(t: t));

  @override Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('DompetKu'), backgroundColor: Colors.transparent),
    body: Column(children: [
      Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20),
        width: double.infinity, decoration: BoxDecoration(gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cP, Color(0xFF8B7FFF)]),
          borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Saldo Saat Ini', style: TextStyle(color: Colors.white70, fontSize: 13)),
          Text(fmt.format(bal), style: const TextStyle(color: Colors.white,
            fontSize: 28, fontWeight: FontWeight.bold))])),
      Expanded(child: tx.isEmpty ? const Center(child: Text('Belum ada transaksi'))
        : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), itemCount: tx.length,
          itemBuilder: (_, i) { final t = tx[i], col = t['i'] == true ? cG : cR;
            return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
              leading: CircleAvatar(backgroundColor: col.withOpacity(0.15),
                child: Icon(t['i'] == true ? Icons.arrow_downward : Icons.arrow_upward, color: col)),
              title: Text(t['t']), subtitle: Text(dfmt.format(DateTime.parse(t['d'])),
                style: const TextStyle(fontSize: 11)),
              trailing: Text('${t['i'] == true ? '+' : '-'}${fmt.format(t['a'])}',
                style: TextStyle(fontWeight: FontWeight.bold, color: col)),
              onTap: () => _struk(t),
              onLongPress: () async { setState(() => tx.removeAt(i)); await _save(); })); })),
    ]),
    floatingActionButton: Row(mainAxisSize: MainAxisSize.min, children: [
      FloatingActionButton.small(heroTag: 'in', backgroundColor: cG,
        onPressed: () => _add(income: true), child: const Icon(Icons.add, color: Colors.white)),
      const SizedBox(width: 8),
      FloatingActionButton.small(heroTag: 'out', backgroundColor: cR,
        onPressed: () => _add(), child: const Icon(Icons.remove, color: Colors.white)),
    ]));
}

class _Struk extends StatelessWidget {
  final Map t; const _Struk({required this.t});
  @override Widget build(BuildContext c) {
    final key = GlobalKey();
    return Container(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(color: Color(0xFFF7F8FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        RepaintBoundary(key: key, child: Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            const Icon(Icons.storefront, size: 40, color: cP), const SizedBox(height: 8),
            const Text('DOMPETKU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const Text('Struk Digital', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 16), const Divider(), const SizedBox(height: 8),
            _row('Tanggal', dfmt.format(DateTime.parse(t['d']))),
            _row('Jenis', t['i'] == true ? 'Pemasukan' : 'Pengeluaran'),
            const SizedBox(height: 8), const Divider(thickness: 2), const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(t['t'], style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(fmt.format(t['a']), style: TextStyle(fontWeight: FontWeight.bold,
                color: t['i'] == true ? cG : cR))]),
            const SizedBox(height: 16), const Text('Terima kasih 🙏',
              style: TextStyle(fontSize: 12, color: Colors.grey))]))),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () async {
            final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
            final img = await b.toImage(pixelRatio: 3);
            final bytes = await img.toByteData(format: ImageByteFormat.png);
            final dir = await getTemporaryDirectory();
            final file = File('${dir.path}/struk.png');
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            await Share.shareXFiles([XFile(file.path)], text: 'Struk ${t['t']}');
          }, icon: const Icon(Icons.share), label: const Text('Bagikan'))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton.icon(onPressed: () => Navigator.pop(c),
            style: FilledButton.styleFrom(backgroundColor: cP),
            icon: const Icon(Icons.check), label: const Text('Tutup'))),
        ]),
      ]));
  }
  Widget _row(String a, String b) => Padding(padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(a, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text(b, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]));
}