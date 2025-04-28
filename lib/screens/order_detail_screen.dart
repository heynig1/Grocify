// lib/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({required this.orderId, super.key});

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? orderDetails;
  bool isLoading = true;
  final String shopkeeperPhoneNumber = '+919145380160'; // Static phone number

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  // Function to copy phone number to clipboard
  void _copyPhoneNumber() {
    Clipboard.setData(ClipboardData(text: shopkeeperPhoneNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number copied to clipboard')),
    );
  }

  Future<void> fetchOrderDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      print('Fetching order details for orderId: ${widget.orderId}');
      final response = await supabase
          .from('orders')
          .select('*, order_items(*, products(*))')
          .eq('id', widget.orderId)
          .single();
      print('Query response: $response');
      setState(() {
        orderDetails = response;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching order details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching order details: $e')),
      );
      setState(() {
        orderDetails = null;
        isLoading = false;
      });
    }
  }

  String formatDate(String? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = DateTime.parse(timestamp);
    return DateFormat('dd/MM/yy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderDetails == null
              ? const Center(child: Text('Order not found'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Order Number',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              formatDate(orderDetails!['timestamp']),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          orderDetails!['id'].toString().substring(0, 6).toUpperCase(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Items',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              'Total: ₹${orderDetails!['total_amount']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(orderDetails!['order_items'] as List).length}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Status: ${orderDetails!['status']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Items in Order',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        (orderDetails!['order_items'] as List).isEmpty
                            ? const Center(child: Text('No items in this order'))
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: (orderDetails!['order_items'] as List).length,
                                itemBuilder: (context, index) {
                                  final item = orderDetails!['order_items'][index];
                                  final product = item['products'];
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: ListTile(
                                      leading: Image.network(
                                        product['image_url'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.error),
                                      ),
                                      title: Text(product['name']),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Quantity: ${item['quantity']}'),
                                          Text('Price: ₹${product['price']}'),
                                          Text('Subtotal: ₹${(item['quantity'] as int) * (product['price'] as num)}'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 32),
                        const Center(
                          child: Text(
                            'Your order will be ready for pickup in 5 to 10 minutes.',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
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
                      ],
                    ),
                  ),
                ),
    );
  }
}