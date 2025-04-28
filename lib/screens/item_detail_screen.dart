import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ItemDetailScreen({super.key, required this.product});

  @override
  _ItemDetailScreenState createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isFavorite = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkIfFavorite();
  }

  Future<void> checkIfFavorite() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', widget.product['id'])
          .maybeSingle();

      setState(() {
        isFavorite = response != null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking favorites: $e')),
      );
      setState(() {
        isFavorite = false;
      });
    }
  }

  Future<void> addToCart() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add to cart')),
        );
        return;
      }

      // Check if the user exists in the users table
      final userExists = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (userExists == null) {
        // Insert the user with a default name to satisfy the NOT NULL constraint
        await supabase.from('users').insert({
          'id': user.id,
          'name': user.email?.split('@')[0] ?? 'Unknown',
          'email': user.email,
        });
      }

      // Check if the item already exists in the cart for this user
      final existingItem = await supabase
          .from('cart')
          .select()
          .eq('product_id', widget.product['id'])
          .eq('user_id', user.id);

      if (existingItem.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item already in cart!')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Insert the item into the cart
      await supabase.from('cart').insert({
        'product_id': widget.product['id'],
        'user_id': user.id,
        'name': widget.product['name'],
        'price': widget.product['price'],
        'image_url': widget.product['image_url'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> toggleFavorite() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to manage favorites')),
      );
      return;
    }

    setState(() {
      isFavorite = !isFavorite;
    });

    try {
      if (isFavorite) {
        await supabase.from('favorites').insert({
          'product_id': widget.product['id'],
          'user_id': user.id,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to favorites!')),
        );
      } else {
        await supabase
            .from('favorites')
            .delete()
            .eq('product_id', widget.product['id'])
            .eq('user_id', user.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorites: $e')),
      );
      setState(() {
        isFavorite = !isFavorite; // Revert the state if the operation fails
      });
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.product['image_url'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.error)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Product Name
                Text(
                  widget.product['name'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Price
                Text(
                  '₹${widget.product['price']}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).primaryColor, // Green for price
                  ),
                ),
                const SizedBox(height: 16),
                // Stock Availability
                const Text(
                  'Stock availability',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Limited stock',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.3, // Adjust this value based on actual stock data
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor, // Green progress bar
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : addToCart,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Add to cart'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: toggleFavorite,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}