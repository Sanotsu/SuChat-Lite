import 'package:flutter/material.dart';

import '../../../../../shared/widgets/image_preview_helper.dart';
import '../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../data/datasources/douguo/douguo_api_manager.dart';
import '../../../data/models/douguo/douguo_recipe_resp.dart';
import 'full_view_page.dart';
import 'recipe_comments_sheet.dart';

/// 菜谱详情页
class RecipeDetailPage extends StatefulWidget {
  final String recipeId;
  final String recipeName;

  const RecipeDetailPage({
    super.key,
    required this.recipeId,
    required this.recipeName,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage>
    with SingleTickerProviderStateMixin {
  final DouguoApiManager _apiManager = DouguoApiManager();

  DGRecipe? _recipe;
  bool _isLoading = true;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _loadRecipeDetail();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipeDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiManager.getRecipeDetail(
        recipeId: widget.recipeId,
      );

      if (response.result?.recipe != null) {
        setState(() {
          _recipe = response.result!.recipe!;
        });
        _animationController.forward();
      } else {
        setState(() {
          _error = '菜谱数据为空';
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
      });
      rethrow;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? _buildLoadingWidget()
          : _error != null
          ? buildCommonErrorWidget(
              error: _error,
              onRetry: _loadRecipeDetail,
              showBack: true,
              context: context,
            )
          : _buildRecipeDetail(),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
      ),
    );
  }

  Widget _buildRecipeDetail() {
    if (_recipe == null) return const SizedBox();

    return CustomScrollView(
      slivers: [
        // 顶部图片和基本信息
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: Colors.orange[400],
          foregroundColor: Colors.white,
          flexibleSpace: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // 使用LayoutBuilder检测SliverAppBar的展开状态，根据展开比例调整标题样式
              // 如果是滚动到顶部，标题显示为2行（AppBar的高度不够），否则显示为5行
              final double expandRatio =
                  (constraints.maxHeight - kToolbarHeight) /
                  (300 - kToolbarHeight);
              final bool isExpanded = expandRatio > 0.8;

              return FlexibleSpaceBar(
                title: Text(
                  _recipe!.title ?? widget.recipeName,
                  maxLines: isExpanded ? 5 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 背景图片
                    if (_recipe!.photoPath != null ||
                        _recipe!.originalPhotoPath != null)
                      buildNetworkOrFileImage(
                        _recipe!.originalPhotoPath ?? _recipe!.photoPath!,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.restaurant_menu,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),

                    // 渐变遮罩
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // 菜谱详细信息
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // 基本信息卡片
                  _buildBasicInfoCard(),

                  // 食材卡片
                  if (_recipe!.major != null && _recipe!.major!.isNotEmpty)
                    _buildIngredientsCard(),

                  // 制作步骤卡片
                  if (_recipe!.cookstep != null &&
                      _recipe!.cookstep!.isNotEmpty)
                    _buildCookingStepsCard(),

                  // 小贴士卡片
                  if (_recipe!.tips != null && _recipe!.tips!.isNotEmpty)
                    _buildTipsCard(),

                  // 作者信息卡片
                  if (_recipe!.user != null) _buildAuthorCard(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '基本信息',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // 统计信息
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_recipe!.vc != null) ...[
                  _buildStatItem(
                    Icons.visibility,
                    '浏览',
                    _recipe!.vc.toString(),
                  ),
                  const SizedBox(width: 5),
                ],
                if (_recipe!.favoCounts != null) ...[
                  _buildStatItem(
                    Icons.favorite,
                    '收藏',
                    _recipe!.favoCounts.toString(),
                  ),
                  const SizedBox(width: 5),
                ],
                if (_recipe!.commentsCount != null)
                  GestureDetector(
                    onTap: () {
                      if (_recipe!.commentsCount! > 0) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => RecipeCommentsSheet(
                            recipeId: widget.recipeId,
                            initialCommentCount: _recipe!.commentsCount!,
                          ),
                        );
                      }
                    },
                    child: _buildStatItem(
                      Icons.comment,
                      '评论',
                      _recipe!.commentsCount.toString(),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              Text(
                _recipe!.releaseTime ?? _recipe!.createTime ?? "",
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 烹饪信息
          Row(
            children: [
              if (_recipe!.cookTime != null &&
                  _recipe!.cookTime!.isNotEmpty) ...[
                _buildInfoChip(Icons.access_time, _recipe!.cookTime!),
                const SizedBox(width: 5),
              ],
              if (_recipe!.cookDifficultyText != null &&
                  _recipe!.cookDifficultyText!.isNotEmpty)
                _buildInfoChip(Icons.bar_chart, _recipe!.cookDifficultyText!),
            ],
          ),

          // 菜谱故事
          if (_recipe!.cookstory != null && _recipe!.cookstory!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              '菜谱故事',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _recipe!.cookstory!,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],

          // 营养成分
          if (_recipe!.nutritionFactsUrl != null &&
              _recipe!.nutritionFactsUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              '营养成分',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: ListTile(
                title: Text("点击查看营养成分"),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullWebPage(
                        url: _recipe!.nutritionFactsUrl!,
                        title: "${_recipe!.title!}营养成分",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.orange[400]),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(color: Colors.grey[700], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.orange[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.orange[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsCard() {
    var list = _recipe!.major!
        .map((ingredient) => _buildIngredientItem(ingredient))
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: Colors.orange[400]),
              const SizedBox(width: 8),
              const Text(
                '食材清单',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            // 禁用滚动（不加这两个会有问题）
            physics: const NeverScrollableScrollPhysics(),
            // 让 GridView 高度自适应内容
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5 / 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) => list[index],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(DGRecipeMajor ingredient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        //这个食材详情url可以直接使用WebView渲染
        onTap: ingredient.tu != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullWebPage(
                      url: ingredient.tu!,
                      title: ingredient.title,
                    ),
                  ),
                );
              }
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (ingredient.title != null)
              Expanded(
                child: Text(
                  ingredient.title!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: ingredient.tu != null
                        ? Colors.blue
                        : Colors.grey[600],
                  ),
                ),
              ),
            if (ingredient.note != null)
              Expanded(
                child: Text(
                  ingredient.note!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookingStepsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: Colors.orange[400]),
              const SizedBox(width: 8),
              const Text(
                '制作步骤',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...(_recipe!.cookstep!.asMap().entries.map((entry) {
            int index = entry.key;
            DGCookStep step = entry.value;
            return _buildCookingStepItem(step, index + 1);
          })),
        ],
      ),
    );
  }

  Widget _buildCookingStepItem(DGCookStep step, int stepNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤编号
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.orange[400],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 步骤内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 步骤图片
                if (step.image != null || step.thumb != null)
                  Container(
                    width: double.infinity,
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: buildImageViewCarouselSlider([
                        step.image ?? step.thumb!,
                      ], aspectRatio: 4 / 3),
                    ),
                  ),

                // 步骤描述
                if (step.content != null)
                  Text(
                    step.content!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.orange[400]),
              const SizedBox(width: 8),
              const Text(
                '小贴士',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Text(
              _recipe!.tips!,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorCard() {
    final user = _recipe!.user!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.orange[400]),
              const SizedBox(width: 8),
              const Text(
                '作者信息',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // 作者头像
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
                child: ClipOval(
                  child: user.avatarMedium != null || user.userPhoto != null
                      ? buildNetworkOrFileImage(
                          user.avatarMedium ?? user.userPhoto!,
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.person, color: Colors.grey[400]),
                ),
              ),

              const SizedBox(width: 16),

              // 作者信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nickname ?? user.nick ?? '未知用户',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (user.lvl != null)
                      Text(
                        'Lv.${user.lvl}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    if (user.isPrime == true)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'VIP',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
