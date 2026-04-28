import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../services/auth_service.dart';
import 'missions_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CategoryService _categoryService = CategoryService();
  final AuthService _authService = AuthService();
  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  List<CategoryModel> categories = [];
  List<CategoryModel> filteredCategories = [];
  String userName = 'Usuario';
  
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  String get userInitials {
    final parts = userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      loadUserData(),
      loadCategories(),
    ]);
  }

  Future<void> loadUserData() async {
    try {
      final savedName = await _authService.getUserName();

      if (!mounted) return;

      setState(() {
        userName = (savedName != null && savedName.trim().isNotEmpty)
            ? savedName.trim()
            : 'Usuario';
      });

      print('USER NAME EN HOME: $userName');
    } catch (e) {
      print('ERROR CARGANDO USUARIO: $e');

      if (!mounted) return;
      setState(() {
        userName = 'Usuario';
      });
    }
  }

  Future<void> loadCategories() async {
    try {
      final result = await _categoryService.getCategories();

      print('CATEGORIAS RECIBIDAS: ${result.length}');
      print(result.map((e) => e.name).toList());

      if (!mounted) return;
      setState(() {
        categories = result;
        filteredCategories = result;
      });
    } catch (e) {
      print('ERROR CARGANDO CATEGORIAS: $e');

      if (!mounted) return;
      setState(() {
        categories = [];
        filteredCategories = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando categorías: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterCategories(String query) {
    final q = query.toLowerCase().trim();

    setState(() {
      if (q.isEmpty) {
        filteredCategories = categories;
      } else {
        filteredCategories = categories.where((category) {
          return category.name.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  IconData getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'electricidad':
        return Icons.bolt;
      case 'plomería':
      case 'plomeria':
        return Icons.plumbing;
      case 'arreglos':
        return Icons.theater_comedy_outlined;
      case 'mudanzas':
        return Icons.local_shipping_outlined;
      default:
        return Icons.home_repair_service;
    }
  }

  Color getCategoryColor(String name) {
    switch (name.toLowerCase()) {
      case 'electricidad':
        return const Color(0xFF3B82F6);
      case 'plomería':
      case 'plomeria':
        return const Color(0xFFF97316);
      case 'arreglos':
        return const Color(0xFF8B5CF6);
      case 'mudanzas':
        return const Color(0xFF0EA5E9);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color getCategoryBgColor(String name) {
    switch (name.toLowerCase()) {
      case 'electricidad':
        return const Color(0xFFEFF6FF);
      case 'plomería':
      case 'plomeria':
        return const Color(0xFFFFF1E8);
      case 'arreglos':
        return const Color(0xFFF5EEFF);
      case 'mudanzas':
        return const Color(0xFFEFF8FF);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildHomeContent(),
                        const MissionsPage(),
                        const Center(child: Text('Mensajes')),
                        const ProfilePage(),
                      ],
                    ),
                  ),
                  _buildBottomNav(context),
                ],
              ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: loadInitialData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 22),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildExpressCard(),
              const SizedBox(height: 24),
              _buildPublishButton(context),
              const SizedBox(height: 28),
              _buildCategoryHeader(),
              const SizedBox(height: 18),
              _buildCategoriesGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(27),
          ),
          child: Center(
            child: Text(
              userInitials,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $userName',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '¿En qué te ayudamos?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(27),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_outlined,
                size: 28,
                color: Color(0xFF0F172A),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: filterCategories,
        decoration: const InputDecoration(
          hintText: 'Busca servicios, trabajadores...',
          prefixIcon: Icon(Icons.search, color: Color(0xFF64748B), size: 28),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 20),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildExpressCard() {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2563EB),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: Container(
                color: const Color(0xFF2563EB),
                padding: const EdgeInsets.fromLTRB(18, 20, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Prioritario',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Misiones Express',
                      style: TextStyle(
                        fontSize: 24,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '¿Necesitas ayuda ahora?\nPublica una misión urgente.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: () {
                        // Action to publish express mission
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Text(
                          'Publicar Urgente',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: Container(
                color: const Color(0xFFA8D3F0),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      color: const Color(0x551E3A8A),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 82,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 10,
          shadowColor: const Color(0x332563EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        onPressed: () {
          print('Selecciona una categoría para publicar una misión');
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0x33FFFFFF),
              child: Icon(Icons.add, color: Colors.white, size: 26),
            ),
            SizedBox(width: 12),
            Text(
              'Publicar misión',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Categorías',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: const Row(
            children: [
              Text(
                'Ver todas',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    if (filteredCategories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 30),
        child: Center(
          child: Text(
            'No se encontraron categorías',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      itemCount: filteredCategories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final category = filteredCategories[index];
        final color = getCategoryColor(category.name);
        final bgColor = getCategoryBgColor(category.name);

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/category-services',
              arguments: category,
            );
          },
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        getCategoryIcon(category.name),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomItem(
            icon: Icons.home_filled,
            label: 'Inicio',
            selected: _currentIndex == 0,
            onTap: () {
              setState(() => _currentIndex = 0);
              _pageController.jumpToPage(0);
            },
          ),
          _BottomItem(
            icon: Icons.assignment_outlined,
            label: 'Misiones',
            selected: _currentIndex == 1,
            onTap: () {
              setState(() => _currentIndex = 1);
              _pageController.jumpToPage(1);
            },
          ),
          _BottomItem(
            icon: Icons.chat_bubble_outline,
            label: 'Mensajes',
            selected: _currentIndex == 2,
            onTap: () {
              setState(() => _currentIndex = 2);
              _pageController.jumpToPage(2);
            },
          ),
          _BottomItem(
            icon: Icons.person_outline,
            label: 'Perfil',
            selected: _currentIndex == 3,
            onTap: () {
              setState(() => _currentIndex = 3);
              _pageController.jumpToPage(3);
            },
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _BottomItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
