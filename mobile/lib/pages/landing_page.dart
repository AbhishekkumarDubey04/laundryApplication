import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../store/auth_provider.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final List<Map<String, dynamic>> services = [
    {
      'title': 'Washing & Fold',
      'desc': 'Everyday wardrobe wash. Thorough washing using premium detergents, dried cleanly and folded.',
      'price': 'Starting at ₹20 / item',
      'icon': LucideIcons.shirt,
      'imageUrl': 'https://images.unsplash.com/photo-1545173168-9f19472ef7f4?w=500&auto=format&fit=crop&q=60',
    },
    {
      'title': 'Dry Cleaning',
      'desc': 'Specialist care for designer dresses, heavy sarees, suits, curtains, and delicate silks.',
      'price': 'Starting at ₹60 / item',
      'icon': LucideIcons.sparkles,
      'imageUrl': 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=500&auto=format&fit=crop&q=60',
    },
    {
      'title': 'Steam Pressing',
      'desc': 'Crisp crease control. Creaseless ironing using high-pressure steam. Delivered on hangers.',
      'price': 'Starting at ₹10 / item',
      'icon': LucideIcons.checkCircle,
      'imageUrl': 'https://images.unsplash.com/photo-1525971977907-22d555db64c0?w=500&auto=format&fit=crop&q=60',
    }
  ];

  final List<Map<String, String>> testimonials = [
    {
      'name': 'Rohan Sharma',
      'location': 'Gurugram',
      'comment': 'Super fast express service. My suit came back looking brand new. Definitely recommend!',
    },
    {
      'name': 'Ananya Iyer',
      'location': 'Bengaluru',
      'comment': 'The convenience of doorstep pickup is a lifesaver. Regular washing is clean and folded perfectly.',
    },
    {
      'name': 'Vikram Malhotra',
      'location': 'Mumbai',
      'comment': 'Same day laundry delivery is a game changer in India. Affordable rates and excellent support.',
    }
  ];

  final List<Map<String, String>> faqs = [
    {
      'q': 'How does Doorstep Pickup work?',
      'a': 'Simply select your services, add clothing items to your cart, pick a convenient pickup date & time slot, and check out. Our agent will arrive at your address with custom laundry bags and deliver them back fresh within 24-72 hours.'
    },
    {
      'q': 'What is the processing time?',
      'a': 'Standard delivery takes 3 days. Express delivery takes 24 hours (₹50 extra). Same-day delivery is available if booked before 11 AM (₹100 extra).'
    },
    {
      'q': 'Is there a minimum order value?',
      'a': 'Yes, orders with a cart subtotal above ₹500 get free delivery! For orders below ₹500, a standard delivery fee of ₹30 applies.'
    }
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isDark = auth.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LaundryIndia',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: isDark ? const Color(0xFF7DA0CA) : const Color(0xFF021024),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => auth.toggleTheme(),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: auth.isAuthenticated
                ? ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      auth.isAdmin ? '/admin' : '/dashboard',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.brightness == Brightness.dark ? const Color(0xFF021024) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Dashboard'),
                  )
                : ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.brightness == Brightness.dark ? const Color(0xFF021024) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Login'),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF051630), const Color(0xFF021024)]
                      : [const Color(0xFFE6EDF5), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7DA0CA).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.sparkles, size: 14, color: isDark ? const Color(0xFF7DA0CA) : const Color(0xFF021024)),
                        const SizedBox(width: 6),
                        Text(
                          'Premium Doorstep Laundry India',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF7DA0CA) : const Color(0xFF021024),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fresh Clothes,\nDoorstep Pickup\nIn Just 24 Hours.',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: isDark ? Colors.white : const Color(0xFF021024),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Professional washing, dry cleaning, and steam pressing services across major Indian cities.',
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF021024),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Schedule Free Pickup', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('15,000+', 'Orders Completed', theme, isDark),
                _buildStatItem('4.9 ★', 'Google Rating', theme, isDark),
                _buildStatItem('24 Hours', 'Express Delivery', theme, isDark),
              ],
            ),
            const SizedBox(height: 32),

            // Services
            Text('Our Services', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...services.map((s) => _buildServiceCard(s, theme, isDark)),
            const SizedBox(height: 32),

            // Testimonials
            Text('Loved by Our Customers', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: testimonials.map((t) => _buildTestimonialCard(t, theme, isDark)).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // FAQs
            Text('Frequently Asked Questions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...faqs.map((faq) => _buildFaqItem(faq, theme, isDark)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String val, String desc, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF7DA0CA) : const Color(0xFF021024),
          ),
        ),
        Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> s, ThemeData theme, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              s['imageUrl'] as String,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(height: 140, color: Colors.grey.shade300),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['title'] as String, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(s['desc'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                Text(
                  s['price'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF7DA0CA) : const Color(0xFF021024),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(Map<String, String> t, ThemeData theme, bool isDark) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '"${t['comment']}"',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF7DA0CA).withOpacity(0.3),
                child: Text(t['name']![0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t['name']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(t['location']!, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFaqItem(Map<String, String> faq, ThemeData theme, bool isDark) {
    return ExpansionTile(
      title: Text(faq['q']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(faq['a']!, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4)),
        )
      ],
    );
  }
}
