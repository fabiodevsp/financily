import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF0A0E1A);
  static const surface   = Color(0xFF0F1629);
  static const card      = Color(0xFF151C35);
  static const border    = Color(0xFF1E2D50);
  static const cyan      = Color(0xFF00D4FF);
  static const cyanDim   = Color(0xFF0099BB);
  static const income    = Color(0xFF00E676);
  static const expense   = Color(0xFFFF4D6A);
  static const purple    = Color(0xFF7C5CEF);
  static const amber     = Color(0xFFFFC947);
  static const white     = Color(0xFFECF1FF);
  static const muted     = Color(0xFF5A6B99);
}

class _Grad {
  static const cyanBlue = [Color(0xFF00D4FF), Color(0xFF0070F3)];
  static const incomeG  = [Color(0xFF00E676), Color(0xFF00897B)];
  static const expenseG = [Color(0xFFFF4D6A), Color(0xFFAD1457)];
  static const purpleG  = [Color(0xFF7C5CEF), Color(0xFF4527A0)];
  static const cardG    = [Color(0xFF151C35), Color(0xFF0F1629)];
  static const glassG   = [Color(0x1A00D4FF), Color(0x050D1F3C)];
}

// ─────────────────────────────────────────────
//  MOCK DATA
// ─────────────────────────────────────────────
class _MockTransaction {
  final String merchant, category;
  final double amount;
  final bool isIncome;
  final IconData icon;
  final Color color;
  const _MockTransaction({
    required this.merchant,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.icon,
    required this.color,
  });
}

final _transactions = [
  _MockTransaction(merchant: 'iFood', category: 'Alimentação', amount: 89.90, isIncome: false, icon: Icons.restaurant_rounded, color: _C.amber),
  _MockTransaction(merchant: 'Salário', category: 'Receita', amount: 8500.00, isIncome: true, icon: Icons.account_balance_rounded, color: _C.income),
  _MockTransaction(merchant: 'Spotify', category: 'Assinatura', amount: 21.90, isIncome: false, icon: Icons.music_note_rounded, color: _C.purple),
  _MockTransaction(merchant: 'Uber', category: 'Transporte', amount: 34.50, isIncome: false, icon: Icons.directions_car_rounded, color: _C.cyan),
  _MockTransaction(merchant: 'Netflix', category: 'Assinatura', amount: 45.90, isIncome: false, icon: Icons.play_circle_rounded, color: _C.expense),
];

// ─────────────────────────────────────────────
//  DASHBOARD SCREEN
// ─────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _scoreCtrl;
  late Animation<double> _scoreAnim;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scoreCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _scoreAnim = CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic);

    final itemCount = 5;
    _slideAnims = List.generate(itemCount, (i) => Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: Interval(i * 0.12, 0.7 + i * 0.06, curve: Curves.easeOutCubic),
    )));

    _fadeAnims = List.generate(itemCount, (i) => Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: Interval(i * 0.12, 0.8 + i * 0.04, curve: Curves.easeOut),
    )));

    _entryCtrl.forward();
    _scoreCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) => FadeTransition(
    opacity: _fadeAnims[index],
    child: SlideTransition(position: _slideAnims[index], child: child),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _animated(0, const _BalanceSummaryCard()),
                const SizedBox(height: 20),
                _animated(1, _FinancialHealthScoreCard(animation: _scoreAnim)),
                const SizedBox(height: 20),
                _animated(2, const _SpendingHeatmapWidget()),
                const SizedBox(height: 20),
                _animated(3, const _CategoryPieWidget()),
                const SizedBox(height: 20),
                _animated(4, const _RecentTransactionsCard()),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  SliverAppBar _buildAppBar() => SliverAppBar(
    backgroundColor: _C.bg,
    expandedHeight: 100,
    pinned: true,
    elevation: 0,
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_C.bg, _C.bg.withOpacity(0)],
          ),
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bom dia, Fabio', style: TextStyle(color: _C.muted, fontSize: 12, fontWeight: FontWeight.w400)),
              Text('Financily', style: TextStyle(
                color: _C.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                shadows: [Shadow(color: _C.cyan.withOpacity(0.4), blurRadius: 12)],
              )),
            ],
          ),
          Row(
            children: [
              _NavIcon(icon: Icons.notifications_none_rounded, badge: true),
              const SizedBox(width: 8),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: _Grad.cyanBlue),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildBottomNav() => Container(
    height: 72,
    decoration: BoxDecoration(
      color: _C.surface,
      border: Border(top: BorderSide(color: _C.border, width: 0.5)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _BottomNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', active: true),
        _BottomNavItem(icon: Icons.upload_file_rounded, label: 'Upload'),
        _BottomNavItem(icon: Icons.auto_graph_rounded, label: 'Analytics'),
        _BottomNavItem(icon: Icons.smart_toy_rounded, label: 'AI Chat'),
        _BottomNavItem(icon: Icons.settings_rounded, label: 'Config'),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
//  BALANCE SUMMARY CARD
// ─────────────────────────────────────────────
class _BalanceSummaryCard extends StatelessWidget {
  const _BalanceSummaryCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D1B3E), Color(0xFF0A0E1A)],
      ),
      borderColor: _C.cyan.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Resumo — Maio 2026',
                style: TextStyle(color: _C.muted, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.cyan.withOpacity(0.3)),
                ),
                child: Text('Ao vivo', style: TextStyle(color: _C.cyan, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text('Saldo Atual', style: TextStyle(color: _C.muted, fontSize: 12)),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(colors: _Grad.cyanBlue).createShader(r),
                  child: const Text('R\$ 3.847,20',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(height: 0.5, color: _C.border),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _BalancePill(label: 'Receitas', value: 'R\$ 8.500', colors: _Grad.incomeG, icon: Icons.arrow_upward_rounded)),
              Container(width: 0.5, height: 40, color: _C.border),
              Expanded(child: _BalancePill(label: 'Despesas', value: 'R\$ 4.652', colors: _Grad.expenseG, icon: Icons.arrow_downward_rounded)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  final String label, value;
  final List<Color> colors;
  final IconData icon;
  const _BalancePill({required this.label, required this.value, required this.colors, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: _C.muted, fontSize: 11)),
              Text(value, style: const TextStyle(color: _C.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FINANCIAL HEALTH SCORE CARD
// ─────────────────────────────────────────────
class _FinancialHealthScoreCard extends StatelessWidget {
  final Animation<double> animation;
  const _FinancialHealthScoreCard({required this.animation});

  @override
  Widget build(BuildContext context) {
    const score = 73.0;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Score de Saúde Financeira',
            style: TextStyle(color: _C.muted, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (_, __) => CustomPaint(
                    size: const Size(160, 160),
                    painter: _HealthArcPainter(progress: animation.value * score / 100, score: score),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ScoreDetailRow(label: 'Controle', value: 82, color: _C.income),
                    const SizedBox(height: 10),
                    _ScoreDetailRow(label: 'Economia', value: 65, color: _C.cyan),
                    const SizedBox(height: 10),
                    _ScoreDetailRow(label: 'Previsão', value: 71, color: _C.amber),
                    const SizedBox(height: 10),
                    _ScoreDetailRow(label: 'Dívidas', value: 90, color: _C.income),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.cyan.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.cyan.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: _C.cyan, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seu score melhorou +5 pts este mês. Reduza assinaturas para atingir 85.',
                    style: TextStyle(color: _C.white.withOpacity(0.8), fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthArcPainter extends CustomPainter {
  final double progress;
  final double score;
  const _HealthArcPainter({required this.progress, required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) - 16;
    const startAngle = math.pi * 0.75;
    const sweepTotal = math.pi * 1.5;

    // Track background
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle, sweepTotal, false,
      Paint()
        ..color = _C.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // Gradient arc
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepTotal,
      colors: const [Color(0xFF00E676), Color(0xFF00D4FF), Color(0xFF7C5CEF)],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle, sweepTotal * progress, false,
      Paint()
        ..shader = gradient
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // Center score text
    final scorePainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(text: '${(progress * score).round()}', style: const TextStyle(color: _C.white, fontSize: 36, fontWeight: FontWeight.w900)),
          TextSpan(text: '/100', style: TextStyle(color: _C.muted, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scorePainter.paint(canvas, Offset(cx - scorePainter.width / 2, cy - scorePainter.height / 2 - 8));

    final labelPainter = TextPainter(
      text: TextSpan(text: 'BOM', style: TextStyle(color: _C.cyan, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, Offset(cx - labelPainter.width / 2, cy + 18));
  }

  @override
  bool shouldRepaint(_HealthArcPainter old) => old.progress != progress;
}

class _ScoreDetailRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _ScoreDetailRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: _C.muted, fontSize: 11)),
            Text('$value', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: _C.border,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SPENDING HEATMAP
// ─────────────────────────────────────────────
class _SpendingHeatmapWidget extends StatelessWidget {
  const _SpendingHeatmapWidget();

  static const _days = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
  static const _values = [
    [0.1, 0.4, 0.9, 0.2, 0.6, 1.0, 0.3],
    [0.5, 0.2, 0.7, 0.8, 0.1, 0.4, 0.6],
    [0.8, 0.9, 0.3, 0.5, 0.7, 0.2, 0.4],
    [0.2, 0.6, 0.4, 0.9, 0.3, 0.8, 0.1],
  ];

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mapa de Gastos — 4 semanas',
                style: TextStyle(color: _C.muted, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
              _Chip(label: 'Últimas 4 sem'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _days.map((d) => SizedBox(
              width: 32,
              child: Center(child: Text(d, style: TextStyle(color: _C.muted, fontSize: 11, fontWeight: FontWeight.w600))),
            )).toList(),
          ),
          const SizedBox(height: 8),
          ..._values.map((week) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: week.map((v) => _HeatCell(intensity: v)).toList(),
            ),
          )),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Baixo', style: TextStyle(color: _C.muted, fontSize: 10)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(colors: [Color(0xFF0A1628), Color(0xFF00D4FF)]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('Alto', style: TextStyle(color: _C.muted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  final double intensity;
  const _HeatCell({required this.intensity});

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(const Color(0xFF0A1628), _C.cyan, intensity)!;
    return Container(
      width: 32, height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(6),
        boxShadow: intensity > 0.6
          ? [BoxShadow(color: _C.cyan.withOpacity(intensity * 0.3), blurRadius: 6)]
          : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CATEGORY PIE WIDGET (FL Chart substituted with custom painter)
// ─────────────────────────────────────────────
class _CategoryPieWidget extends StatefulWidget {
  const _CategoryPieWidget();
  @override
  State<_CategoryPieWidget> createState() => _CategoryPieWidgetState();
}

class _CategoryPieWidgetState extends State<_CategoryPieWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _selected = -1;

  static const _categories = [
    ('Alimentação', 0.32, _C.amber),
    ('Assinaturas', 0.18, _C.purple),
    ('Transporte', 0.14, _C.cyan),
    ('Saúde', 0.10, _C.income),
    ('Outros', 0.26, Color(0xFF4A5568)),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribuição por Categoria',
            style: TextStyle(color: _C.muted, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 140, height: 140,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => CustomPaint(
                    painter: _PiePainter(
                      categories: _categories,
                      progress: _anim.value,
                      selected: _selected,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: List.generate(_categories.length, (i) {
                    final c = _categories[i];
                    return GestureDetector(
                      onTap: () => setState(() => _selected = _selected == i ? -1 : i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selected == i ? c.$3.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selected == i ? c.$3.withOpacity(0.5) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: c.$3, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(c.$1, style: const TextStyle(color: _C.white, fontSize: 12))),
                            Text('${(c.$2 * 100).round()}%',
                              style: TextStyle(color: c.$3, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<(String, double, Color)> categories;
  final double progress;
  final int selected;
  const _PiePainter({required this.categories, required this.progress, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = math.min(cx, cy) - 4;
    final innerR = outerR * 0.55;
    var startAngle = -math.pi / 2;

    for (var i = 0; i < categories.length; i++) {
      final c = categories[i];
      final sweep = 2 * math.pi * c.$2 * progress;
      final isSelected = selected == i;
      final offset = isSelected ? 6.0 : 0.0;
      final midAngle = startAngle + sweep / 2;
      final dx = math.cos(midAngle) * offset;
      final dy = math.sin(midAngle) * offset;

      canvas.drawPath(
        Path()
          ..moveTo(cx + dx + math.cos(startAngle) * innerR, cy + dy + math.sin(startAngle) * innerR)
          ..arcTo(Rect.fromCircle(center: Offset(cx + dx, cy + dy), radius: outerR), startAngle, sweep, false)
          ..arcTo(Rect.fromCircle(center: Offset(cx + dx, cy + dy), radius: innerR), startAngle + sweep, -sweep, false)
          ..close(),
        Paint()
          ..color = c.$3.withOpacity(isSelected ? 1.0 : 0.8)
          ..style = PaintingStyle.fill,
      );

      if (isSelected) {
        canvas.drawPath(
          Path()
            ..moveTo(cx + dx + math.cos(startAngle) * innerR, cy + dy + math.sin(startAngle) * innerR)
            ..arcTo(Rect.fromCircle(center: Offset(cx + dx, cy + dy), radius: outerR + 2), startAngle, sweep, false)
            ..arcTo(Rect.fromCircle(center: Offset(cx + dx, cy + dy), radius: innerR), startAngle + sweep, -sweep, false)
            ..close(),
          Paint()
            ..color = c.$3.withOpacity(0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      startAngle += sweep;
    }

    // Center label
    final tp = TextPainter(
      text: const TextSpan(
        children: [
          TextSpan(text: 'R\$ 4.652\n', style: TextStyle(color: _C.white, fontSize: 13, fontWeight: FontWeight.w800)),
          TextSpan(text: 'total', style: TextStyle(color: _C.muted, fontSize: 10)),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: innerR * 2);
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_PiePainter old) => old.progress != progress || old.selected != selected;
}

// ─────────────────────────────────────────────
//  RECENT TRANSACTIONS CARD
// ─────────────────────────────────────────────
class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Últimas Transações',
                style: TextStyle(color: _C.muted, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: Text('Ver todas', style: TextStyle(color: _C.cyan, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._transactions.asMap().entries.map((entry) => _RecentTransactionsTile(
            tx: entry.value,
            isLast: entry.key == _transactions.length - 1,
          )),
        ],
      ),
    );
  }
}

class _RecentTransactionsTile extends StatelessWidget {
  final _MockTransaction tx;
  final bool isLast;
  const _RecentTransactionsTile({required this.tx, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: tx.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tx.color.withOpacity(0.25)),
                ),
                child: Icon(tx.icon, color: tx.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.merchant,
                      style: const TextStyle(color: _C.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(tx.category,
                      style: TextStyle(color: _C.muted, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tx.isIncome ? '+' : '-'} R\$ ${tx.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: tx.isIncome ? _C.income : _C.expense,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text('Hoje', style: TextStyle(color: _C.muted, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        if (!isLast) Container(height: 0.5, color: _C.border),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED COMPONENTS
// ─────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final Color? borderColor;

  const _GlassCard({required this.child, this.gradient, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _Grad.cardG,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? _C.border, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _C.border.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: _C.muted, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool badge;
  const _NavIcon({required this.icon, this.badge = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: _C.surface,
            shape: BoxShape.circle,
            border: Border.all(color: _C.border),
          ),
          child: Icon(icon, color: _C.white, size: 20),
        ),
        if (badge) Positioned(
          right: 4, top: 4,
          child: Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: _C.expense, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _BottomNavItem({required this.icon, required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: active ? _C.cyan : _C.muted, size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: active ? _C.cyan : _C.muted, fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
        if (active) ...[
          const SizedBox(height: 4),
          Container(width: 16, height: 2, decoration: BoxDecoration(color: _C.cyan, borderRadius: BorderRadius.circular(1))),
        ],
      ],
    );
  }
}
