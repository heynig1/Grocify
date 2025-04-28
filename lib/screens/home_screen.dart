// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool _loading = true;
  int _selectedTabIndex = 0; // For category tabs
  int _selectedNavIndex = 0; // For bottom navigation bar
  String _searchQuery = ''; // For search functionality
  List<String> categories = ['All']; // Start with 'All' as the default category

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() {
      _loading = true; // Show loading indicator during fetch
    });
    try {
      final response = await supabase.from('products').select();
      setState(() {
        products = List<Map<String, dynamic>>.from(response);

        // Extract unique categories from the products
        final uniqueCategories = products
            .map((product) => product['category']?.toString())
            .where((category) => category != null && category.isNotEmpty)
            .toSet()
            .toList();
        categories = ['All', ...uniqueCategories.whereType<String>()];

        _filterProducts();
        _loading = false;
      });
    } catch (e) {
      print('Error fetching products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching products: $e')),
      );
      setState(() {
        _loading = false;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
      _filterProducts();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterProducts();
    });
  }

  void _filterProducts() {
    setState(() {
      filteredProducts = products.where((product) {
        // Filter by category
        final matchesCategory = _selectedTabIndex == 0 ||
            (product['category']?.toString().toLowerCase() ==
                categories[_selectedTabIndex].toLowerCase());
        // Filter by search query
        final matchesSearch = _searchQuery.isEmpty ||
            product['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    switch (index) {
      case 0:
        // Already on HomeScreen
        break;
      case 1:
        Navigator.pushNamed(context, '/favorites').then((_) {
          // Refresh products when returning from another screen
          fetchProducts();
        });
        break;
      case 2:
        Navigator.pushNamed(context, '/cart').then((_) {
          // Refresh products when returning from the cart screen
          fetchProducts();
        });
        break;
      case 3:
        Navigator.pushNamed(context, '/account').then((_) {
          // Refresh products when returning from another screen
          fetchProducts();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchProducts, // Trigger fetchProducts on swipe-down
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Ensure scrollable for RefreshIndicator
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      filled: true,
                      fillColor: const Color(0xFFE8F5E9), // Light green
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    ),
                  ),
                ),
                // Category Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value;
                        return _buildTab(category, index);
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Main Content
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredProducts.isEmpty
                        ? const Center(child: Text('No products available'))
                        : Column(
                            children: [
                              // Product Cards
                              ...filteredProducts.map((product) => _buildProductCard(context, product)),
                              const SizedBox(height: 16),
                            ],
                          ),
              ],
            ),
          ),
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _onNavTapped,
        selectedItemColor: Theme.of(context).primaryColor, // Green for selected item
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: _selectedTabIndex == index ? FontWeight.bold : FontWeight.normal,
                color: _selectedTabIndex == index
                    ? Theme.of(context).primaryColor
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            if (_selectedTabIndex == index)
              Container(
                height: 2,
                width: 20,
                color: Theme.of(context).primaryColor, // Green underline
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    final stock = product['stock'] as int;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/itemDetail',
          arguments: product,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: Image.network(
                  product['image_url'],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.error)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  product['name'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '₹${product['price']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor, // Green for price
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  stock > 0
                      ? (stock <= 5 ? 'Low Stock ($stock left)' : 'In Stock ($stock left)')
                      : 'Out of Stock',
                  style: TextStyle(
                    fontSize: 14,
                    color: stock > 0
                        ? (stock <= 5 ? Colors.orange : Colors.green)
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}