import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0F),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const MyApp());
}

// ─────────────────────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────────────────────

class Task {
  String id;
  String title;
  String note;
  bool done;
  String type; // 'study' | 'general'
  DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.note = '',
    this.done = false,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'done': done,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'],
        title: j['title'],
        note: j['note'] ?? '',
        done: j['done'],
        type: j['type'],
        createdAt: DateTime.parse(j['createdAt']),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  COLORS & THEME
// ─────────────────────────────────────────────────────────────────────────────

const _bg       = Color(0xFF0A0A0F);
const _surface  = Color(0xFF13131C);
const _card     = Color(0xFF1B1B28);
const _border   = Color(0xFF252535);
const _txt1     = Color(0xFFF0F0FA);
const _txt2     = Color(0xFF8080A0);
const _txt3     = Color(0xFF3A3A55);

// Study  — violet / purple
const _studyA   = Color(0xFF8B5CF6);
const _studyB   = Color(0xFF6D28D9);
const _studyBg  = Color(0xFF1A1428);

// General — emerald / teal
const _genA     = Color(0xFF10B981);
const _genB     = Color(0xFF059669);
const _genBg    = Color(0xFF0D1F18);

Color _accent(String type)  => type == 'study' ? _studyA : _genA;
Color _accentB(String type) => type == 'study' ? _studyB : _genB;
Color _modeBg(String type)  => type == 'study' ? _studyBg : _genBg;

// ─────────────────────────────────────────────────────────────────────────────
//  APP ROOT
// ─────────────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          background: _bg,
          surface: _surface,
          primary: _studyA,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tasks') ?? '[]';
    final list = jsonDecode(raw) as List;
    setState(() => _tasks = list.map((e) => Task.fromJson(e)).toList());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks', jsonEncode(_tasks.map((t) => t.toJson()).toList()));
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  void _add(String title, String note, String type) {
    setState(() => _tasks.insert(0, Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          note: note,
          type: type,
          createdAt: DateTime.now(),
        )));
    _save();
  }

  void _edit(Task task, String title, String note) {
    setState(() {
      task.title = title;
      task.note = note;
    });
    _save();
  }

  void _toggle(Task task) {
    setState(() => task.done = !task.done);
    _save();
  }

  void _delete(Task task) {
    setState(() => _tasks.remove(task));
    _save();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _activeType => _tab.index == 0 ? 'study' : 'general';

  List<Task> _of(String type) =>
      _tasks.where((t) => t.type == type).toList();

  int _done(String type) => _of(type).where((t) => t.done).length;

  double _progress(String type) {
    final all = _of(type).length;
    return all == 0 ? 0 : _done(type) / all;
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _TaskList(
                  tasks: _of('study'),
                  type: 'study',
                  onToggle: _toggle,
                  onDelete: _delete,
                  onEdit: (t) => _showSheet(context, existing: t),
                ),
                _TaskList(
                  tasks: _of('general'),
                  type: 'general',
                  onToggle: _toggle,
                  onDelete: _delete,
                  onEdit: (t) => _showSheet(context, existing: t),
                ),
              ],
            ),
          ),
        ]),
      ),
      floatingActionButton: _FAB(
        type: _activeType,
        onTap: () => _showSheet(context),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent(_activeType), _accentB(_activeType)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Focus',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _txt1,
                letterSpacing: -0.5,
              )),
          const Spacer(),
          Text(
            '${_done(_activeType)}/${_of(_activeType).length} done',
            style: TextStyle(fontSize: 13, color: _txt2, fontWeight: FontWeight.w600),
          ),
        ]),
        const SizedBox(height: 20),
        // Progress cards row
        Row(children: [
          Expanded(child: _ProgressCard(type: 'study', progress: _progress('study'),
              count: _of('study').length, done: _done('study'))),
          const SizedBox(width: 12),
          Expanded(child: _ProgressCard(type: 'general', progress: _progress('general'),
              count: _of('general').length, done: _done('general'))),
        ]),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [_accent(_activeType), _accentB(_activeType)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
            color: _accent(_activeType).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: _txt2,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: '📚  Study'),
          Tab(text: '✅  General'),
        ],
      ),
    );
  }

  void _showSheet(BuildContext context, {Task? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskSheet(
        type: existing?.type ?? _activeType,
        existing: existing,
        onSave: (title, note) {
          if (existing != null) {
            _edit(existing, title, note);
          } else {
            _add(title, note, _activeType);
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROGRESS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final String type;
  final double progress;
  final int count;
  final int done;
  const _ProgressCard({required this.type, required this.progress,
      required this.count, required this.done});

  @override
  Widget build(BuildContext context) {
    final a = _accent(type);
    final b = _accentB(type);
    final label = type == 'study' ? '📚 Study' : '✅ General';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _modeBg(type),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: a.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: a)),
        const SizedBox(height: 10),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: _border,
            valueColor: AlwaysStoppedAnimation(a),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Text('$done/$count',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _txt1)),
          const Spacer(),
          Text('${(progress * 100).round()}%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: a)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TASK LIST
// ─────────────────────────────────────────────────────────────────────────────

class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  final String type;
  final Function(Task) onToggle;
  final Function(Task) onDelete;
  final Function(Task) onEdit;

  const _TaskList({
    required this.tasks,
    required this.type,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(type == 'study' ? '📚' : '✅',
              style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('No ${type == 'study' ? 'study' : 'general'} tasks yet',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _txt1)),
          const SizedBox(height: 6),
          Text('Tap + to add one',
              style: const TextStyle(fontSize: 14, color: _txt2)),
        ]),
      );
    }

    // Pending first, completed at bottom
    final pending = tasks.where((t) => !t.done).toList();
    final done    = tasks.where((t) => t.done).toList();
    final ordered = [...pending, ...done];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: ordered.length + (done.isNotEmpty && pending.isNotEmpty ? 1 : 0),
      itemBuilder: (_, i) {
        // Section header for completed
        if (pending.isNotEmpty && done.isNotEmpty && i == pending.length) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 10),
            child: Row(children: [
              const Expanded(child: Divider(color: _border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Completed (${done.length})',
                    style: const TextStyle(fontSize: 12, color: _txt2, fontWeight: FontWeight.w600)),
              ),
              const Expanded(child: Divider(color: _border)),
            ]),
          );
        }
        final idx = (pending.isNotEmpty && done.isNotEmpty && i > pending.length)
            ? i - 1
            : i;
        return _TaskCard(
          task: ordered[idx],
          onToggle: () => onToggle(ordered[idx]),
          onDelete: () => onDelete(ordered[idx]),
          onEdit: () => onEdit(ordered[idx]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TASK CARD
// ─────────────────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final a = _accent(task.type);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4560).withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFF4560).withOpacity(0.4)),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFFF4560), size: 24),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: task.done ? _surface : _card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: task.done ? _border : a.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(children: [
              // Accent strip
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: task.done ? _txt3 : a,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18)),
                ),
              ),
              // Checkbox
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.done ? a : Colors.transparent,
                      border: Border.all(
                        color: task.done ? a : _txt3,
                        width: 2,
                      ),
                    ),
                    child: task.done
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              // Text content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: task.done ? _txt3 : _txt1,
                          decoration: task.done
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: _txt3,
                        ),
                      ),
                      if (task.note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: task.done ? _txt3 : _txt2),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Edit icon
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(Icons.edit_outlined, size: 16,
                    color: task.done ? _txt3 : _txt2),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FAB
// ─────────────────────────────────────────────────────────────────────────────

class _FAB extends StatelessWidget {
  final String type;
  final VoidCallback onTap;
  const _FAB({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58, height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_accent(type), _accentB(type)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _accent(type).withOpacity(0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ADD / EDIT BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _TaskSheet extends StatefulWidget {
  final String type;
  final Task? existing;
  final Function(String title, String note) onSave;

  const _TaskSheet({required this.type, this.existing, required this.onSave});

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _noteCtrl  = TextEditingController(text: widget.existing?.note ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    widget.onSave(title, _noteCtrl.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final a = _accent(widget.type);
    final b = _accentB(widget.type);
    final label = widget.type == 'study' ? '📚 Study' : '✅ General';

    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // Handle
        Center(
          child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(height: 22),
        // Header row
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: a.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: a.withOpacity(0.35)),
            ),
            child: Text(label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: a)),
          ),
          const SizedBox(width: 10),
          Text(isEdit ? 'Edit Task' : 'New Task',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 20, fontWeight: FontWeight.w700, color: _txt1)),
        ]),
        const SizedBox(height: 22),
        // Title field
        _Field(
          controller: _titleCtrl,
          focusNode: _focus,
          hint: widget.type == 'study'
              ? 'e.g. Complete Chapter 3 notes'
              : 'e.g. Buy groceries',
          accent: a,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 12),
        // Note field
        _Field(
          controller: _noteCtrl,
          hint: 'Add a note (optional)',
          accent: a,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        // Save button
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _submit,
            child: AnimatedBuilder(
              animation: _titleCtrl,
              builder: (_, __) {
                final enabled = _titleCtrl.text.trim().isNotEmpty;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: enabled
                        ? LinearGradient(colors: [a, b])
                        : null,
                    color: enabled ? null : _border,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: enabled
                        ? [BoxShadow(color: a.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      isEdit ? 'Save Changes' : 'Add Task',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: enabled ? Colors.white : _txt2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color accent;
  final FocusNode? focusNode;
  final int maxLines;
  final Function(String)? onSubmitted;

  const _Field({
    required this.controller,
    required this.hint,
    required this.accent,
    this.focusNode,
    this.maxLines = 1,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      textInputAction: maxLines == 1 ? TextInputAction.done : TextInputAction.newline,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 15, color: _txt1, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _txt3, fontSize: 14),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
