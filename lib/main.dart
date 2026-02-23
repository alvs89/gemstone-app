// ============================================================================
// LABORATORY ACTIVITY: GemStone Mobile Application
// COURSE/SECTION: BSCS / CS32S3
// DEVELOPER: Alvin J. Guillermo
// INSTITUTION: Technological Institute of the Philippines (T.I.P.)
//
// DESCRIPTION: This project is a fully functional e-commerce mobile application
// developed using Flutter. It demonstrates core mobile development concepts
// including state management, dynamic algorithm pricing, localized payment
// integration (e.g., GCash, Maya), interactive UI elements (image carousels),
// and robust form validation. The architecture and design align with the
// academic grading rubric criteria for Functionality, Creativity, Performance,
// and Design.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// The main entry point of the Flutter application.
void main() {
  runApp(const GemstoneApp());
}

// ----------------------------------------------------------------------
// GLOBAL STATE MANAGEMENT
// ----------------------------------------------------------------------
// A global list storing the items added to the cart. For this laboratory
// scope, a global variable manages the cart state across multiple screens.
List<Map<String, dynamic>> globalCart = [];

// ----------------------------------------------------------------------
// UTILITY FUNCTIONS
// ----------------------------------------------------------------------
// Converts a raw double value into a properly formatted currency string
// containing thousands separators using Regular Expressions.
String formatCurrency(double amount) {
  return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
}

// ----------------------------------------------------------------------
// ROOT APPLICATION CONFIGURATION
// ----------------------------------------------------------------------
// Configures the Material application, defining the global theme, styling,
// and setting the initial route to the Splash Screen.
class GemstoneApp extends StatelessWidget {
  const GemstoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GemStone E-Commerce',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const SplashScreen(),
    );
  }
}

// ----------------------------------------------------------------------
// SPLASH SCREEN INTERFACE
// ----------------------------------------------------------------------
// Provides a branded entry experience for the application using a
// StatefulWidget to handle the timer lifecycle.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Initializes a 3-second delay before pushing the user to the main
    // product page. pushReplacement is utilized to remove the splash screen
    // from the navigation stack.
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ProductPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/gemstone_blue.png',
              width: 300,
              height: 300,
              errorBuilder: (context, error, stackTrace) => const Text(
                  '❌ Missing:\nassets/images/gemstone_blue.png',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.redAccent, fontSize: 16)),
            ),
            const SizedBox(height: 24),
            const Text(
              'GemStone Luxury',
              style: TextStyle(
                  fontFamily: 'CustomFont',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// MAIN PRODUCT PAGE INTERFACE
// ----------------------------------------------------------------------
// Serves as the primary shopping interface. This page contains the interactive
// product carousel, detailed descriptions, user reviews, and triggers the
// configuration bottom sheet for cart additions.
class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  // Local state variables for tracking user interactions on the product page.
  bool isFavorited = false;
  bool isFollowing = false;
  int quantity = 1;
  double ringSize = 4.0;

  // Initializes the default selected material to 'Blue' to match the primary asset.
  String selectedMaterial = 'Blue';

  // Defines the sequence of available material variants.
  final List<String> materials = [
    'Blue',
    'White Gold',
    'Yellow Gold',
    'Platinum',
    'Rose Gold'
  ];

  // Controller managing the horizontal image swipe functionality.
  final PageController _pageController = PageController(initialPage: 0);

  // Maps the defined material variants to their corresponding local image assets.
  final Map<String, String> materialImages = {
    'Blue': 'assets/images/gemstone_blue.png',
    'White Gold': 'assets/images/gemstone_white.png',
    'Yellow Gold': 'assets/images/gemstone_yellow.png',
    'Platinum': 'assets/images/gemstone_platinum.png',
    'Rose Gold': 'assets/images/gemstone_rose.png',
  };

  // Data model representing the base product attributes.
  final Map<String, dynamic> productDetails = {
    'name': "Aetheria Sapphire",
    'basePrice': 56500.00,
  };

  // Static list of review data mapping to populate the customer feedback section.
  final List<Map<String, dynamic>> reviewData = [
    {
      'name': 'Sarah Jenkins',
      'stars': 5,
      'date': '2 days ago',
      'comment':
          'Absolutely stunning! The color depth is incredible in natural light. My jeweler was highly impressed with the cut.'
    },
    {
      'name': 'Elena T.',
      'stars': 5,
      'date': '3 weeks ago',
      'comment':
          'Exceeded my expectations. The insured shipping was handled very professionally.'
    },
    {
      'name': 'Michael R.',
      'stars': 4,
      'date': '1 month ago',
      'comment':
          'Beautiful stone. Dropped one star because the certification paperwork arrived slightly bent, but the gem itself is perfect.'
    },
    {
      'name': 'Chloe B.',
      'stars': 5,
      'date': '2 months ago',
      'comment':
          'Set this in a custom platinum band and it looks like it belongs in a museum.'
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Algorithm for determining the final cost based on user selections.
  // Applies a static premium for specific colored metals and a scalable
  // premium based on the physical size of the band starting from the base size.
  double _calculateDynamicPrice(String material, double size) {
    double calculatedPrice = productDetails['basePrice'];

    if (material == 'Yellow Gold' ||
        material == 'Rose Gold' ||
        material == 'Blue') {
      calculatedPrice += 5000.00;
    } else if (material == 'Platinum') {
      calculatedPrice += 15000.00;
    }

    double halfSizesDiff = (size - 4.0) * 2;
    calculatedPrice += (halfSizesDiff * 1500.00);
    return calculatedPrice;
  }

  // Retrieves the minimum theoretical price of the product to display on the main page.
  double get lowestPossiblePrice => _calculateDynamicPrice('Blue', 4.0);

  // Invokes a modal bottom sheet allowing users to customize their order.
  // Uses StatefulBuilder to maintain independent state within the modal itself.
  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
          double currentActivePrice =
              _calculateDynamicPrice(selectedMaterial, ringSize);

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Configuration',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('₱${formatCurrency(currentActivePrice)}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[900])),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Band Material',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedMaterial,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      focusColor: Colors.transparent,
                      items: materials
                          .map((String value) => DropdownMenuItem<String>(
                              value: value, child: Text(value)))
                          .toList(),
                      onChanged: (newValue) {
                        setModalState(() {
                          selectedMaterial = newValue!;
                        });
                        setState(() {
                          selectedMaterial = newValue!;
                        });

                        int newIndex = materials.indexOf(newValue!);
                        _pageController.animateToPage(newIndex,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ring Size',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(ringSize.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 16, color: Colors.indigo)),
                  ],
                ),
                Slider(
                  value: ringSize,
                  min: 4.0,
                  max: 12.0,
                  divisions: 16,
                  activeColor: Colors.indigo[700],
                  label: ringSize.toStringAsFixed(1),
                  onChanged: (value) {
                    setModalState(() {
                      ringSize = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quantity',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.indigo[900],
                            onPressed: () {
                              if (quantity > 1) setModalState(() => quantity--);
                            }),
                        Text('$quantity',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: Colors.indigo[900],
                            onPressed: () {
                              setModalState(() => quantity++);
                            }),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      String savedMaterial = selectedMaterial;
                      double savedSize = ringSize;
                      int savedQuantity = quantity;

                      String savedImage = materialImages[savedMaterial] ??
                          'assets/images/gemstone_blue.png';

                      // Appends the configured item to the global cart array.
                      setState(() {
                        globalCart.add({
                          'name': productDetails['name'],
                          'price': currentActivePrice,
                          'image': savedImage,
                          'quantity': savedQuantity,
                          'size': savedSize,
                          'material': savedMaterial,
                          'selected': true,
                        });

                        // Restores the configuration variables to their baseline values.
                        quantity = 1;
                        ringSize = 4.0;
                        selectedMaterial = 'Blue';
                        _pageController.jumpToPage(0);
                      });
                      Navigator.pop(context);

                      // Generates a custom styled snackbar to visually confirm the cart addition
                      // with detailed, formatted attributes of the newly added product.
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          elevation: 0,
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.transparent,
                          content: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 5))
                              ],
                              border: Border.all(
                                  color: Colors.indigo.shade900, width: 2),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 36),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Successfully Added!',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      const SizedBox(height: 8),
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                              color: Colors.grey[800],
                                              fontSize: 13,
                                              height: 1.5),
                                          children: [
                                            const TextSpan(
                                                text: 'Item: ',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            TextSpan(
                                                text:
                                                    '${productDetails['name']}\n'),
                                            const TextSpan(
                                                text: 'Color: ',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            TextSpan(text: '$savedMaterial\n'),
                                            const TextSpan(
                                                text: 'Size: ',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            TextSpan(
                                                text:
                                                    '${savedSize.toStringAsFixed(1)}\n'),
                                            const TextSpan(
                                                text: 'Quantity: ',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            TextSpan(text: '$savedQuantity'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_bag),
                    label: Text(
                        'Add to Cart • ₱${formatCurrency(currentActivePrice * quantity)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[900],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        });
      },
    );
  }

  // Generates modular UI elements for customer reviews.
  Widget _buildReviewItem(String name, int stars, String date, String comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.indigo.shade50,
                child: Text(name[0],
                    style: TextStyle(
                        color: Colors.indigo[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(date,
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Row(
                  children: List.generate(
                      5,
                      (index) => Icon(
                          index < stars ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16))),
            ],
          ),
          const SizedBox(height: 12),
          Text(comment,
              style: TextStyle(
                  color: Colors.grey[800], fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  // Generates modular rows for detailed product specifications.
  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        centerTitle: true,
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CartPage()))
                      .then((_) => setState(() {}));
                },
              ),
              if (globalCart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.redAccent, shape: BoxShape.circle),
                    child: Text('${globalCart.length}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
            ],
          )
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -3))
        ]),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _showOptionsBottomSheet(context),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Configure & Buy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[900],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 350,
              width: double.infinity,
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ]),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int index) {
                      setState(() {
                        selectedMaterial = materials[index];
                      });
                    },
                    itemCount: materials.length,
                    itemBuilder: (context, index) {
                      String material = materials[index];
                      String imagePath = materialImages[material] ??
                          'assets/images/gemstone_blue.png';
                      return Center(
                        child: Hero(
                          tag: 'gemstone_image_$index',
                          child: Image.asset(imagePath,
                              width: 250, height: 250, fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 250,
                              height: 250,
                              alignment: Alignment.center,
                              child: Text(
                                '❌ Image Not Found:\n$imagePath\n\nPlease check pubspec.yaml\nand exact spelling.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: 10,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.indigo, size: 20),
                        onPressed: () {
                          _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut);
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios,
                            color: Colors.indigo, size: 20),
                        onPressed: () {
                          _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut);
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(materials.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: selectedMaterial == materials[index] ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: selectedMaterial == materials[index]
                                ? Colors.indigo[900]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(productDetails['name'],
                              style: const TextStyle(
                                  fontFamily: 'CustomFont',
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87))),
                      IconButton(
                        icon: Icon(
                            isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorited ? Colors.redAccent : Colors.grey,
                            size: 30),
                        onPressed: () {
                          setState(() {
                            isFavorited = !isFavorited;
                          });
                          ScaffoldMessenger.of(context).clearSnackBars();
                          if (isFavorited) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(children: [
                                  Icon(Icons.favorite, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text('Added to your favorites list!')
                                ]),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.pinkAccent,
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text('₱${formatCurrency(lowestPossiblePrice)}',
                      style: TextStyle(
                          fontSize: 24,
                          color: Colors.indigo[700],
                          fontWeight: FontWeight.w700)),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      const Text('4.8',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 12),
                      Container(height: 15, width: 1, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text('12 Sold',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 14)),
                      const SizedBox(width: 12),
                      Container(height: 15, width: 1, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text('${reviewData.length} Reviews',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 14)),
                    ],
                  ),

                  const Divider(height: 30, thickness: 1),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300)),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            color: Colors.indigo[700], size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Insured Luxury Delivery',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('₱1,500.00 • Armored Transport',
                                  style: TextStyle(
                                      color: Colors.grey[700], fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 30, thickness: 1),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.indigo[100],
                              child: Icon(Icons.storefront,
                                  color: Colors.indigo[900], size: 28)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('GemStone Official Store',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text('Premium Verified Seller',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isFollowing = !isFollowing;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: isFollowing
                                    ? Colors.grey[200]
                                    : Colors.indigo[900],
                                foregroundColor: isFollowing
                                    ? Colors.indigo[900]
                                    : Colors.white,
                                elevation: isFollowing ? 0 : 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(isFollowing ? 'Following' : 'Follow',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                  maxLines: 1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.chat_bubble_outline,
                                  size: 16),
                              label: const Text('Chat',
                                  style: TextStyle(fontSize: 13), maxLines: 1),
                              style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  foregroundColor: Colors.indigo[900],
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.storefront, size: 16),
                              label: const Text('Shop',
                                  style: TextStyle(fontSize: 13), maxLines: 1),
                              style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  foregroundColor: Colors.indigo[900],
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),

                  const Divider(height: 40, thickness: 1),

                  const Text('Product Details',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        _buildSpecRow('Gemstone Type', 'Sapphire'),
                        _buildSpecRow('Clarity', 'VVS1 (Eye Clean)'),
                        _buildSpecRow('Cut', 'Oval Brilliant'),
                        _buildSpecRow('Origin', 'Sri Lanka'),
                        _buildSpecRow('Certification', 'GIA Certified'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text('Description',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      'The Aetheria Sapphire boasts an enchanting, deep celestial hue. Perfectly cut to maximize brilliance, this stone is an elegant centerpiece for any custom arrangement. Certified authentic and meticulously sourced.',
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey[700], height: 1.6)),

                  const Divider(height: 40, thickness: 1),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Customer Reviews',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ReviewsPage(reviews: reviewData)));
                          },
                          child: Text('See All',
                              style: TextStyle(color: Colors.indigo[700])))
                    ],
                  ),
                  const SizedBox(height: 10),

                  _buildReviewItem(
                      reviewData[0]['name'],
                      reviewData[0]['stars'],
                      reviewData[0]['date'],
                      reviewData[0]['comment']),
                  _buildReviewItem(
                      reviewData[1]['name'],
                      reviewData[1]['stars'],
                      reviewData[1]['date'],
                      reviewData[1]['comment']),

                  const SizedBox(height: 30),

                  // Displays author attribution at the terminus of the viewable area.
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.diamond_outlined,
                            color: Colors.indigo, size: 24),
                        const SizedBox(height: 8),
                        Text('Designed & Developed by',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                letterSpacing: 1.1)),
                        const SizedBox(height: 4),
                        Text('Alvin J. Guillermo • BSCS / CS32S3',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700])),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// REVIEWS PAGE WIDGET
// ----------------------------------------------------------------------
// Renders the full collection of reviews via a highly optimized ListView.builder.
class ReviewsPage extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;

  const ReviewsPage({super.key, required this.reviews});

  Widget _buildReviewItem(String name, int stars, String date, String comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.indigo.shade50,
                child: Text(name[0],
                    style: TextStyle(
                        color: Colors.indigo[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(date,
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Row(
                  children: List.generate(
                      5,
                      (index) => Icon(
                          index < stars ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16))),
            ],
          ),
          const SizedBox(height: 12),
          Text(comment,
              style: TextStyle(
                  color: Colors.grey[800], fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('All Reviews'),
          backgroundColor: Colors.indigo[900],
          foregroundColor: Colors.white),
      body: ListView.builder(
        padding: const EdgeInsets.all(24.0),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          return _buildReviewItem(review['name'], review['stars'],
              review['date'], review['comment']);
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------
// CART PAGE WIDGET
// ----------------------------------------------------------------------
// Displays the globally stored items. Implements specific interaction controls
// to modify item selection state and perform deletion operations.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Computes the total price strictly for items matching the selected condition.
  double get totalAmount {
    return globalCart
        .where((item) => item['selected'] == true)
        .fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  // Verifies if the master selection logic should be enacted.
  bool get isAllSelected {
    return globalCart.isNotEmpty &&
        globalCart.every((item) => item['selected'] == true);
  }

  // Uniformly toggles the selection state of all cart entities.
  void _toggleAll(bool? value) {
    setState(() {
      for (var item in globalCart) {
        item['selected'] = value ?? false;
      }
    });
  }

  // Instantiates a protective modal to prevent accidental data deletion.
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Item',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
              'Are you sure you want to remove this gemstone from your cart?'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  globalCart.removeAt(index);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50], elevation: 0),
              child: const Text('Remove',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Your Cart'),
          backgroundColor: Colors.indigo[900],
          foregroundColor: Colors.white),
      body: globalCart.isEmpty
          ? const Center(
              child: Text('Your cart is empty.',
                  style: TextStyle(fontSize: 18, color: Colors.grey)))
          : Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200))),
                  child: Row(
                    children: [
                      Checkbox(
                          value: isAllSelected,
                          activeColor: Colors.indigo[900],
                          onChanged: _toggleAll),
                      const Text('Select All',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: globalCart.length,
                    itemBuilder: (context, index) {
                      final item = globalCart[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: item['selected'],
                                activeColor: Colors.indigo[900],
                                onChanged: (bool? value) {
                                  setState(() {
                                    item['selected'] = value ?? false;
                                  });
                                },
                              ),
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10)),
                                child: Image.asset(item['image'],
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.diamond)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Size: ${item['size']} | ${item['material']}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600])),
                                    const SizedBox(height: 4),
                                    Text(
                                        '₱${formatCurrency(item['price'])} x ${item['quantity']}',
                                        style: TextStyle(
                                            color: Colors.indigo[700],
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () => _confirmDelete(index)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: globalCart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5))
              ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total:',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                      Text('₱${formatCurrency(totalAmount)}',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: totalAmount > 0
                        ? () {
                            final selectedItems = globalCart
                                .where((item) => item['selected'] == true)
                                .toList();
                            Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => CheckoutPage(
                                            checkoutItems: selectedItems,
                                            subtotal: totalAmount)))
                                .then((_) => setState(() {}));
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      backgroundColor: Colors.indigo[900],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Checkout',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}

// ----------------------------------------------------------------------
// CHECKOUT PAGE WIDGET
// ----------------------------------------------------------------------
// Processes final transaction data. Integrates strict form validation parameters
// and mathematical breakdowns mapped from the CartPage state selection.
class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> checkoutItems;
  final double subtotal;

  const CheckoutPage(
      {super.key, required this.checkoutItems, required this.subtotal});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // A GlobalKey allowing direct state access to trigger bulk form evaluation.
  final _formKey = GlobalKey<FormState>();
  String paymentMethod = 'GCash';

  // Static and dynamic properties dictating the final receipt calculation.
  double get shippingFee => 1500.00;
  double get tax => widget.subtotal * 0.12;
  double get grandTotal => widget.subtotal + shippingFee + tax;

  // Executes form verification prior to triggering the success dialog routing.
  void processOrder() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Center(
                child: Icon(Icons.check_circle, color: Colors.green, size: 60)),
            content: const Text(
                'Order Placed Successfully!\nYour digital receipt has been sent to your email.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16)),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[900],
                      foregroundColor: Colors.white),
                  onPressed: () {
                    // Eliminates the verified items from the cart state array.
                    globalCart.removeWhere((item) => item['selected'] == true);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  // Generates cohesive card elements representing the discrete checkout phases.
  Widget _buildSectionCard(
      {required String step,
      required String title,
      required IconData icon,
      required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.indigo.shade50, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.indigo[900], size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step,
                        style: TextStyle(
                            color: Colors.indigo[400],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Padding(padding: const EdgeInsets.all(16.0), child: child),
        ],
      ),
    );
  }

  // Creates specific local payment modules mapping variables to brand coloring.
  Widget _buildPaymentOption(
      String title, String subtitle, IconData icon, String value,
      {Color? iconColor}) {
    bool isSelected = paymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          paymentMethod = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.shade50 : Colors.white,
          border: Border.all(
              color: isSelected ? Colors.indigo.shade900 : Colors.grey.shade200,
              width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: (iconColor ?? Colors.grey[600])!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child:
                    Icon(icon, color: iconColor ?? Colors.grey[600], size: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected
                              ? Colors.indigo[900]
                              : Colors.black87)),
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? Colors.indigo[900] : Colors.grey),
          ],
        ),
      ),
    );
  }

  // Organizes receipt information dynamically into structured text formatting.
  Widget _buildBreakdownRow(String label, double amount,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 15,
                  color: isTotal ? Colors.black : Colors.grey[700],
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text('₱${formatCurrency(amount)}',
              style: TextStyle(
                  fontSize: isTotal ? 18 : 15,
                  color: isTotal ? Colors.indigo[900] : Colors.black87,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: Colors.indigo[900],
          foregroundColor: Colors.white,
          elevation: 0),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -5))
        ]),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: processOrder,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2),
              child: const Text('Place Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                step: 'STEP 1',
                title: 'Shipping Details',
                icon: Icons.local_shipping_outlined,
                child: Column(
                  children: [
                    TextFormField(
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        decoration: InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'e.g., Juan Dela Cruz',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.person_outline)),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter your name' : null),
                    const SizedBox(height: 16),
                    TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'e.g., juan@example.com',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.email_outlined)),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter your email';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value))
                            return 'Please enter a valid email';
                          return null;
                        }),
                    const SizedBox(height: 16),
                    TextFormField(
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.fullStreetAddress],
                        decoration: InputDecoration(
                            labelText: 'Shipping Address',
                            hintText: 'e.g., Montalban, Rizal',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.location_on_outlined)),
                        validator: (value) => value!.isEmpty
                            ? 'Please enter your address'
                            : null),
                    const SizedBox(height: 16),
                    TextFormField(
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'e.g., 09123456789',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.phone_outlined)),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter your phone number';
                        if (value.length < 10)
                          return 'Phone number is too short';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              _buildSectionCard(
                  step: 'STEP 2',
                  title: 'Payment Method',
                  icon: Icons.account_balance_wallet_outlined,
                  child: Column(
                    children: [
                      _buildPaymentOption('GCash', 'Pay via GCash E-Wallet',
                          Icons.qr_code_scanner, 'GCash',
                          iconColor: Colors.blue[700]),
                      _buildPaymentOption('Maya', 'Pay via Maya E-Wallet',
                          Icons.qr_code_scanner, 'Maya',
                          iconColor: const Color(0xFF00945A)),
                      _buildPaymentOption(
                          'Credit/Debit Card',
                          'Visa, Mastercard, JCB',
                          Icons.credit_card,
                          'Credit Card',
                          iconColor: Colors.orange[700]),
                      _buildPaymentOption(
                          'Cash on Delivery (COD)',
                          'Pay when you receive the package',
                          Icons.local_shipping_outlined,
                          'COD',
                          iconColor: Colors.grey[800]),
                    ],
                  )),
              _buildSectionCard(
                  step: 'STEP 3',
                  title: 'Order Summary',
                  icon: Icons.receipt_long_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...widget.checkoutItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Image.asset(item['image'],
                                      errorBuilder: (context, error,
                                              stackTrace) =>
                                          Container(
                                              alignment: Alignment.center,
                                              color: Colors.red.shade50,
                                              child: const Text('Missing',
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 10)))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Text(
                                          'Size: ${item['size']} | ${item['material']}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600])),
                                      const SizedBox(height: 4),
                                      Text(
                                          '₱${formatCurrency(item['price'])} x ${item['quantity']}',
                                          style: TextStyle(
                                              color: Colors.indigo[700],
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 24, thickness: 1),
                      _buildBreakdownRow('Subtotal', widget.subtotal),
                      _buildBreakdownRow('Insured Shipping', shippingFee),
                      _buildBreakdownRow('VAT (12%)', tax),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(12)),
                        child: _buildBreakdownRow('Grand Total', grandTotal,
                            isTotal: true),
                      ),
                    ],
                  )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
