import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preferences_controller.dart';

/// SANCTIONED STOCK-MATERIAL EXCEPTION (M6 §2 / Part K flag 4).
///
/// This is the disguise. It deliberately ignores the Lamplight design system
/// and renders as a plain Google-Keep-style notes app in light Material —
/// Roboto, grey checkboxes, blue accents. Using the Sahaj palette here would
/// defeat the disguise. DO NOT "fix" this toward the design system.
///
/// When Book Mode is on, the cover sits over the app until a discreet
/// double-tap dismisses it for this foreground session. Backgrounding (any
/// route) re-arms the cover so the recents thumbnail shows the notes app,
/// never the last real screen.
class BookModeCover extends ConsumerStatefulWidget {
  const BookModeCover({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<BookModeCover> createState() => _BookModeCoverState();
}

class _BookModeCoverState extends ConsumerState<BookModeCover>
    with WidgetsBindingObserver {
  bool _dismissed = false;
  int? _openNote; // null = list, index = note detail

  static const _blue = Color(0xFF1A73E8);
  static const _ink = Color(0xFF202124);
  static const _grey = Color(0xFF5F6368);
  static const _faint = Color(0xFF80868B);
  static const _hair = Color(0xFFE8EAED);
  static const _paper = Color(0xFFFAFAFA);

  // Canned, mundane, Indian-household — authored once, never generated from
  // anything real (M6 §2). Static dates within the last ~6 weeks.
  static const _notes = <(String, String)>[
    ('Grocery — Saturday', 'Edited 8 Jun, 7:42 PM'),
    ('Meeting notes — Tue', 'Edited 5 Jun, 11:10 AM'),
    ('Books to read', 'Edited 1 Jun, 9:30 PM'),
    ('Ideas', 'Edited 28 May, 4:15 PM'),
    ('Bills to pay', 'Edited 24 May, 8:02 AM'),
    ('Trip checklist', 'Edited 19 May, 6:48 PM'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-arm on background so the recents thumbnail is the cover, not the app.
    if (state != AppLifecycleState.resumed &&
        ref.read(preferencesControllerProvider).bookMode) {
      setState(() {
        _dismissed = false;
        _openNote = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookMode = ref.watch(preferencesControllerProvider).bookMode;
    if (!bookMode || _dismissed) return widget.child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        // Double-tap anywhere reveals the app — taught once at onboarding,
        // never hinted on the cover itself.
        onDoubleTap: () => setState(() => _dismissed = true),
        child: Theme(
          data: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(seedColor: _blue),
            scaffoldBackgroundColor: Colors.white,
          ),
          child: _openNote == null ? _buildList() : _buildNote(_openNote!),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notebook',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w500, fontSize: 20)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.search, color: _grey),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: _notes.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: _hair),
        itemBuilder: (context, i) => ListTile(
          leading: const Icon(Icons.notes, color: _grey),
          title: Text(_notes[i].$1,
              style: const TextStyle(color: _ink, fontSize: 16)),
          subtitle: Text(_notes[i].$2,
              style: const TextStyle(color: _faint, fontSize: 12)),
          onTap: () => setState(() => _openNote = i),
        ),
      ),
      // Inert decoy.
      floatingActionButton: FloatingActionButton(
        backgroundColor: _blue,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // One level of depth: a believable, read-only note. The grocery checklist
  // with one ticked item sells "in use". FAB and toolbar are inert decoys.
  Widget _buildNote(int index) {
    final isGrocery = index == 0;
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _grey),
          onPressed: () => setState(() => _openNote = null),
        ),
        actions: const [
          Icon(Icons.push_pin_outlined, color: _grey),
          SizedBox(width: 18),
          Icon(Icons.bookmark_border, color: _grey),
          SizedBox(width: 18),
          Icon(Icons.more_vert, color: _grey),
          SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_notes[index].$1,
                style: const TextStyle(
                    color: _ink, fontSize: 23, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(_notes[index].$2,
                style: const TextStyle(color: _faint, fontSize: 12)),
            const SizedBox(height: 18),
            if (isGrocery)
              ..._groceryBody()
            else
              Text(_plainBody(index),
                  style: const TextStyle(color: _ink, fontSize: 15.5, height: 1.5)),
            const Spacer(),
            const Divider(height: 1, color: _hair),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.add_box_outlined, color: _grey, size: 22),
                  SizedBox(width: 26),
                  Icon(Icons.palette_outlined, color: _grey, size: 22),
                  SizedBox(width: 26),
                  Icon(Icons.undo, color: _grey, size: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _groceryBody() {
    Widget item(String label, {bool ticked = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.5),
          child: Row(
            children: [
              ticked
                  ? Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _grey,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Icon(Icons.check, size: 13, color: Colors.white),
                    )
                  : Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        border: Border.all(color: _grey, width: 2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                    color: ticked ? _faint : _ink,
                    fontSize: 15.5,
                    decoration: ticked ? TextDecoration.lineThrough : null,
                  )),
            ],
          ),
        );

    return [
      item('milk (2)'),
      item('atta — 5 kg'),
      item('batteries AA', ticked: true),
      item('dahi'),
      item('lemon, dhaniya'),
      const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text('ask Mummy re: jeera brand',
            style: TextStyle(color: _grey, fontSize: 15.5)),
      ),
    ];
  }

  String _plainBody(int index) => switch (index) {
        1 => 'Follow up with Sharma re: the Q3 numbers.\n\n'
            'Send the deck before Thursday.\n'
            'Book the conference room for 3 PM.',
        2 => 'The Midnight Library\nSapiens\nThe Psychology of Money',
        3 => 'Repaint the balcony railing.\nFix the kitchen tap.',
        4 => 'Electricity — due 12th\nInternet — due 15th\nGas cylinder',
        _ => 'Charger, power bank\nMeds\nID copies\nUmbrella',
      };
}
