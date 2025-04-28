import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> cartItems = [];
  double totalPrice = 0.0;
  bool isLoading = false;
  int _selectedNavIndex = 2; // Cart is the 3rd item (index 2)

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view your cart')),
        );
        setState(() {
          cartItems = [];
          totalPrice = 0.0;
        });
        return;
      }

      // Fetch cart items with product details (including stock)
      final response = await supabase
          .from('cart')
          .select('*, products!cart_product_id_fkey(name, price, stock, image_url)')
          .eq('user_id', user.id);

      setState(() {
        cartItems = List<Map<String, dynamic>>.from(response);
        calculateTotalPrice();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching cart items: $e')),
      );
      setState(() {
        cartItems = [];
        totalPrice = 0.0;
      });
    }
  }

  void calculateTotalPrice() {
    totalPrice = cartItems.fold(0, (sum, item) {
      final price = (item['products']['price'] as num).toDouble();
      final quantity = (item['quantity'] as int? ?? 1);
      return sum + (price * quantity);
    });
  }

  Future<void> updateQuantity(int productId, int newQuantity) async {
    if (newQuantity < 1) {
      await removeFromCart(productId);
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to manage your cart')),
        );
        return;
      }

      await supabase
          .from('cart')
          .update({'quantity': newQuantity})
          .eq('product_id', productId)
          .eq('user_id', user.id);

      await fetchCartItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating quantity: $e')),
      );
    }
  }

  Future<void> removeFromCart(int productId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to manage your cart')),
        );
        return;
      }

      await supabase
          .from('cart')
          .delete()
          .eq('product_id', productId)
          .eq('user_id', user.id);

      await fetchCartItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from cart!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing item: $e')),
      );
    }
  }

  Future<void> placeOrder() async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty!')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to place an order')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Check and update stock for each item in the cart
      for (var item in cartItems) {
        final productId = item['product_id'];
        final quantity = item['quantity'] ?? 1;
        final currentStock = item['products']['stock'];

        // Check if there’s enough stock
        if (currentStock < quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item['products']['name']} is out of stock')),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }

        // Update the stock in the products table
        await supabase
            .from('products')
            .update({'stock': currentStock - quantity})
            .eq('id', productId);
      }

      // Insert the order with user_id
      final orderResponse = await supabase.from('orders').insert({
        'user_id': user.id,
        'total_amount': totalPrice,
        'status': 'processing',
        'timestamp': DateTime.now().toIso8601String(),
      }).select().single();

      // Insert order items with quantities
      for (var item in cartItems) {
        await supabase.from('order_items').insert({
          'order_id': orderResponse['id'],
          'product_id': item['product_id'],
          'quantity': item['quantity'] ?? 1,
        });
      }

      // Clear the cart for this user
      await supabase.from('cart').delete().eq('user_id', user.id);

      // Refresh the cart
      await fetchCartItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );

      // Navigate to OrderDetailScreen with the new order ID
      Navigator.pushNamed(
        context,
        '/orderDetail',
        arguments: orderResponse['id'],
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/favorites');
        break;
      case 2:
        // Already on CartScreen
        break;
      case 3:
        Navigator.pushNamed(context, '/account');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Cart',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            // Cart Items
            Expanded(
              child: cartItems.isEmpty
                  ? const Center(child: Text('Your cart is empty'))
                  : ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final quantity = item['quantity'] ?? 1;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    bottomLeft: Radius.circular(10),
                                  ),
                                  child: Image.network(
                                    item['products']['image_url'],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Center(child: Icon(Icons.error)),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['products']['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${item['products']['price']}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () => updateQuantity(
                                                  item['product_id'], quantity - 1),
                                            ),
                                            Text('$quantity'),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () => updateQuantity(
                                                  item['product_id'], quantity + 1),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => removeFromCart(item['product_id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Total and Place Order Button
            if (cartItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Total: ₹${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isLoading ? null : placeOrder,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Place Order'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _onNavTapped,
        selectedItemColor: Theme.of(context).primaryColor,
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
}