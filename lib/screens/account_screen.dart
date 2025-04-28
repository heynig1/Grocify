// lib/screens/account_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  int _selectedNavIndex = 3; // Account is the 4th item (index 3)
  final String shopkeeperPhoneNumber = '+919145380160'; // Static phone number

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    fetchOrders();
  }

  // Function to copy phone number to clipboard
  void _copyPhoneNumber() {
    Clipboard.setData(ClipboardData(text: shopkeeperPhoneNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number copied to clipboard')),
    );
  }

  Future<void> fetchUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        setState(() {
          userProfile = response;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile: $e')),
        );
      }
    }
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        print('Fetching orders for user: ${user.id}');

        // Get today's date (April 28, 2025) and format it for comparison
        final today = DateTime(2025, 4, 28); // Current date as per system instructions
        final todayStart = DateTime(today.year, today.month, today.day, 0, 0, 0);
        final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

        // Convert to ISO 8601 strings for Supabase query
        final todayStartIso = todayStart.toIso8601String();
        final todayEndIso = todayEnd.toIso8601String();

        // Fetch orders with status 'ready' or 'processing' for today only
        final response = await supabase
            .from('orders')
            .select('*, order_items(*, products(*))')
            .eq('user_id', user.id)
            .inFilter('status', ['ready', 'processing'])
            .gte('timestamp', todayStartIso)
            .lte('timestamp', todayEndIso);

        print('Orders response: $response');
        setState(() {
          orders = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('Error fetching orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching orders: $e')),
      );
      setState(() {
        orders = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/favorites');
        break;
      case 2:
        Navigator.pushNamed(context, '/cart');
        break;
      case 3:
        // Already on AccountScreen
        break;
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'Welcome to our app! By using this app, you agree to the following terms:\n\n'
            '1. **Usage**: This app is for personal use only. Do not use it for commercial purposes without permission.\n'
            '2. **Orders**: All orders are for pick-up only. We do not offer home delivery.\n'
            '3. **Payments**: Payments must be made at the time of pick-up unless otherwise specified.\n'
            '4. **Liability**: We are not responsible for any loss or damage caused by using this app.\n'
            '5. **Changes**: We may update these terms at any time without prior notice.\n\n'
            'Please read these terms carefully before using the app.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. Here’s how we handle your data:\n\n'
            '1. **Data Collection**: We collect your name, email, and phone number to manage your account and orders.\n'
            '2. **Usage**: Your data is used to process orders and improve our services.\n'
            '3. **Security**: We implement reasonable measures to protect your data, but no system is completely secure.\n'
            '4. **Sharing**: We do not share your data with third parties except as required by law.\n'
            '5. **Contact**: If you have any questions about your data, please contact us at support@example.com.\n\n'
            'Your data is safe with us!',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Account',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.mail_outline),
                      onPressed: () {
                        // Add messaging functionality if needed
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // User Profile
                if (userProfile != null) ...[
                  Text(
                    'Name: ${userProfile!['name'] ?? 'Unknown'}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Email: ${userProfile!['email'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phone: ${userProfile!['phone'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                ],
                // Account Settings Section
                const Text(
                  'Account Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.key, color: Colors.grey),
                  title: const Text('Details & Password'),
                  subtitle: const Text('Please enter your credentials'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feature coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.credit_card, color: Colors.grey),
                  title: const Text('Payment Methods'),
                  subtitle: const Text('Choose your preferred payment option'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feature coming soon!')),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Order History Button
                const Text(
                  'Order History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.grey),
                  title: const Text('View Order History'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pushNamed(context, '/orderHistory');
                  },
                ),
                const SizedBox(height: 16),
                // Your Orders Section
                const Text(
                  'Your Orders (Today - Ready/Processing)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : orders.isEmpty
                        ? const Center(child: Text('No orders for today (Ready/Processing)'))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  title: Text('Order ID: ${order['id']}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Status: ${order['status']}'),
                                      Text('Total: ₹${order['total_amount']}'),
                                      const Text('Pick-up Only Order'),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/orderDetail',
                                      arguments: order['id'],
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                const SizedBox(height: 16),
                // Support Section
                const Text(
                  'Support',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.description, color: Colors.grey),
                  title: const Text('Terms & Conditions'),
                  subtitle: const Text('Please read carefully.'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showTermsAndConditions,
                ),
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.grey),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('Your data is safe with us.'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showPrivacyPolicy,
                ),
                const SizedBox(height: 16),
                // Display Phone Number (Copyable)
                Center(
                  child: GestureDetector(
                    onTap: _copyPhoneNumber,
                    child: Text(
                      'Contact Us: $shopkeeperPhoneNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Sign Out Button
                Center(
                  child: ElevatedButton(
                    onPressed: signOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ),
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