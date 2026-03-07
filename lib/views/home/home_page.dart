import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../theme/app_colors.dart';
import '../../models/account.dart';
import '../../viewmodels/account_viewmodel.dart';
import '../../viewmodels/equipment_viewmodel.dart';
import '../../viewmodels/scheme_viewmodel.dart';
import '../../viewmodels/graduation_viewmodel.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/feature_tile.dart';
import '../equipment/equipment_list_page.dart';
import '../simulator/simulator_page.dart';
import '../graduation/graduation_page.dart';
import '../settings/import_export_page.dart';

final homeTabProvider = StateProvider<int>((ref) => 0);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(accountProvider.notifier).load();
      final accountState = ref.read(accountProvider);
      if (accountState.currentAccountId != null) {
        await ref
            .read(equipmentProvider.notifier)
            .loadForAccount(accountState.currentAccountId);
        await ref
            .read(schemeProvider.notifier)
            .loadForAccount(accountState.currentAccountId);
      }
      _checkFirstLaunch();
    });
  }

  void _checkFirstLaunch() {
    final box = Hive.box('settings');
    final shown = box.get('welcome_shown', defaultValue: false) as bool;
    if (!shown && mounted) {
      box.put('welcome_shown', true);
      _showWelcomeDialog();
    }
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.inkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/icon/app_icon.png',
                      width: 64, height: 64),
                ),
                const SizedBox(height: 16),
                Text(
                  '燕云毕业度计算器',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldBright,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v1.1.0',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withAlpha(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '欢迎使用本工具。这是一个专为燕云十六声竞速玩家打造的毕业率计算与装备管理 App。',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _creditSection(
                        '致敬与鸣谢',
                        '本工具的核心算法与逻辑架构深度基于 V佬 (Violetta)@片雲 制作的系列竞速毕业率Excel计算器，'
                            '以及 B站秋夕君 将其网页化重构的在线工具 spongem.com/yysls。'
                            '\n\n本 App 在网页版基础上进行了移动端适配与功能增强，保留毕业率算法的同时，'
                            '提供 OCR 识别录入、多角色管理等便捷交互体验。'
                            '\n\n在此向 V佬、秋夕君 和各流派竞速表二改作者对燕云竞速社区的贡献致以诚挚的谢意。',
                      ),
                      const SizedBox(height: 12),
                      _creditSection(
                        '关于本工具',
                        '• 支持全装备 OCR 拍照识别，自动填充词条\n'
                            '• 多角色 / 多方案管理，数据本地存储\n'
                            '• 毕业率计算、词条优先级、培养建议\n'
                            '• 数据导入导出，换设备无忧',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '注意：部分套装、心法未配置完成，无法生效，请不要选一些过于冷门的配装。',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.goldBright,
                      foregroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('开始使用',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _creditSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.goldBright,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.goldBright,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);

    if (accountState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: accountState.currentAccount == null
          ? _buildWelcome()
          : _buildDashboard(accountState),
    );
  }

  Widget _buildDashboard(AccountState accountState) {
    final tt = Theme.of(context).textTheme;
    final gradState = ref.watch(graduationProvider);
    final equipState = ref.watch(equipmentProvider);
    final equipCount = equipState.equipments.length;
    final schemeState = ref.watch(schemeProvider);
    final currentScheme = schemeState.currentScheme;
    final equippedCount = currentScheme?.equippedItems.values
            .where((v) => v != null && v.isNotEmpty)
            .length ??
        0;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(
            '燕云毕业度计算器',
            style: TextStyle(
              color: AppColors.goldBright,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          backgroundColor: AppColors.ink,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/icon/logo.png', fit: BoxFit.contain),
          ),
          actions: [
            _buildAccountChip(accountState),
            IconButton(
              icon: Icon(Icons.info_outline_rounded,
                  color: AppColors.textMuted, size: 20),
              tooltip: '关于',
              onPressed: _showWelcomeDialog,
            ),
            const SizedBox(width: 4),
          ],
        ),

        // Section: 数据概览
        SliverToBoxAdapter(
          child: _sectionTitle('数据概览', Icons.bar_chart_rounded),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 170,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                StatCard(
                  title: '毕业率',
                  value: '${gradState.currentRate.toStringAsFixed(1)}%',
                  icon: Icons.school_rounded,
                  accentColor: AppColors.goldBright,
                ),
                const SizedBox(width: 12),
                StatCard(
                  title: '轴期望伤害',
                  value: '${gradState.totalDamage}',
                  icon: Icons.flash_on_rounded,
                  accentColor: AppColors.purple,
                ),
                const SizedBox(width: 12),
                StatCard(
                  title: '装备数量',
                  value: '$equipCount',
                  icon: Icons.inventory_2_rounded,
                  accentColor: const Color(0xFF90CAF9),
                  trailing: Text(
                    '已装配 $equippedCount/8',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Section: 功能
        SliverToBoxAdapter(
          child: _sectionTitle('功能', Icons.grid_view_rounded),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              FeatureTile(
                title: '装备管理',
                subtitle: '录入、查看和管理所有装备',
                icon: Icons.inventory_2_rounded,
                accentColor: AppColors.goldBright,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EquipmentListPage()),
                ),
              ),
              FeatureTile(
                title: '面板模拟',
                subtitle: '配置方案、查看属性面板',
                icon: Icons.dashboard_customize_rounded,
                accentColor: const Color(0xFF90CAF9),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SimulatorPage()),
                ),
              ),
              FeatureTile(
                title: '毕业分析',
                subtitle: '毕业率、词条优先级、培养建议',
                icon: Icons.analytics_rounded,
                accentColor: AppColors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const GraduationPage()),
                ),
              ),
              FeatureTile(
                title: '导入导出',
                subtitle: '备份和恢复角色数据',
                icon: Icons.import_export_rounded,
                accentColor: AppColors.textTertiary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ImportExportPage()),
                ),
              ),
            ],
          ),
        ),

        // Current scheme
        if (currentScheme != null)
          SliverToBoxAdapter(
            child: _sectionTitle('当前方案', Icons.description_rounded),
          ),
        if (currentScheme != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inkCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.gold.withAlpha(40)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.goldDim,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withAlpha(50)),
                      ),
                      child: Icon(Icons.description_rounded,
                          color: AppColors.goldBright, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentScheme.name,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '已装配 $equippedCount/8 件装备',
                            style: tt.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SimulatorPage()),
                      ),
                      child: const Text('查看'),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.gold.withAlpha(180)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withAlpha(60),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountChip(AccountState accountState) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded, size: 16,
                color: AppColors.goldBright),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 72),
              child: Text(
                accountState.currentAccount?.name ?? '选择角色',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.expand_more_rounded, size: 16,
                color: AppColors.textMuted),
          ],
        ),
      ),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        for (final account in accountState.accounts) {
          final isCurrent = account.id == accountState.currentAccountId;
          items.add(PopupMenuItem(
            value: account.id,
            child: Row(
              children: [
                if (isCurrent)
                  const Icon(Icons.check_circle, size: 18, color: AppColors.goldBright)
                else
                  Icon(Icons.circle_outlined, size: 18,
                      color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    account.name,
                    style: TextStyle(
                      fontWeight:
                          isCurrent ? FontWeight.w600 : FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18,
                      color: AppColors.danger),
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDeleteAccount(account);
                  },
                ),
              ],
            ),
          ));
        }
        items.add(const PopupMenuDivider());
        items.add(PopupMenuItem(
          value: '__create__',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.goldDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, size: 14, color: AppColors.goldBright),
              ),
              const SizedBox(width: 10),
              Text('新建角色',
                  style: TextStyle(
                      color: AppColors.goldBright, fontWeight: FontWeight.w600)),
            ],
          ),
        ));
        return items;
      },
      onSelected: (value) {
        if (value == '__create__') {
          _showCreateAccountDialog();
        } else {
          ref.read(accountProvider.notifier).selectAccount(value);
          ref.read(equipmentProvider.notifier).loadForAccount(value);
          ref.read(schemeProvider.notifier).loadForAccount(value);
        }
      },
    );
  }

  Widget _buildWelcome() {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.gold.withAlpha(80), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldGlow,
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/icon/app_icon.png',
                    width: 80, height: 80),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              '欢迎使用',
              style: tt.bodyLarge?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              '燕云毕业度计算器',
              style: tt.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.goldBright,
                letterSpacing: 2,
              ),
            ),
            Text(
              '装备毕业率管理器',
              style: tt.bodyLarge?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '请先创建一个角色开始使用',
              style: tt.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: _showCreateAccountDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('新建角色'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 36, vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAccountDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建角色',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入角色名称',
            prefixIcon: Icon(Icons.person_add_rounded),
          ),
          onSubmitted: (_) => _doCreate(controller, context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => _doCreate(controller, context),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _doCreate(TextEditingController controller, BuildContext ctx) {
    final name = controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(ctx);
    ref.read(accountProvider.notifier).createAccount(name).then((_) {
      final id = ref.read(accountProvider).currentAccountId;
      if (id != null) {
        ref.read(equipmentProvider.notifier).loadForAccount(id);
        ref.read(schemeProvider.notifier).loadForAccount(id);
      }
    });
  }

  void _confirmDeleteAccount(Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除角色',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            Text('确定要删除角色「${account.name}」吗？\n所有装备数据将被清除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(accountProvider.notifier).deleteAccount(account.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
