import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mazaoapp/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ProductListScreen(),
    const SellProductScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  // FirebaseAuth instance to get the current user
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    // Fetching the user's information
    _user = _auth.currentUser;
  }

  Future<void> _logout() async {
    await _auth.signOut();
    setState(() {
      _user = null; // Updates the state to reflect the user is logged out
    });
    // navigate to the login screen after logout
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Katalog", style: TextStyle(fontSize: 25.0)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black,),
            onPressed: () {
              // notifications' settings TBD
            },
          ),

        ],
      ),
      body: _screens[_selectedIndex],
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(_user != null ? _user!.displayName ?? 'User Name' : 'Guest'),
              accountEmail: Text(_user != null ? _user!.email ?? 'user@example.com' : 'guest@katalog.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _user != null && _user!.displayName != null
                      ? _user!.displayName![0].toUpperCase()
                      : 'G', // Default to 'G' for guest if no name
                  style: const TextStyle(fontSize: 40.0),
                ),
              ),
              decoration: const BoxDecoration(
                color: Colors.lightGreen,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            if (_user != null) ...[
              // Shows Logout option if the user is logged in
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: _logout,
              ),
            ] else ...[
              // Shows Login option if the user is not logged in
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Login'),
                onTap: _navigateToLogin,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.lightGreen,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.white),
            activeIcon: Icon(Icons.home, color: Colors.black),
            label: 'Buy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell, color: Colors.white),
            activeIcon: Icon(Icons.sell, color: Colors.black),
            label: 'Sell',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart, color: Colors.white),
            activeIcon: Icon(Icons.shopping_cart, color: Colors.black),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.white),
            activeIcon: Icon(Icons.person, color: Colors.black),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String searchQuery = '';
  String sortOption = 'none';

  void showSearchDialog(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Products'),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(hintText: 'Enter product name'),
            onChanged: (value) {
              setState(() {
                searchQuery = value; // Updates search query dynamically wakati user anatype.
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  searchQuery = searchController.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  List<Product> sortProducts(List<Product> products) {
    switch (sortOption) {
      case 'lowToHigh':
        products.sort((a, b) => a.price.compareTo(b.price));
      case 'highToLow':
        products.sort((a, b) => b.price.compareTo(a.price));
      default:

        break;
    }
    return products;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Products'),
        actions: [
            PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.black),
            onSelected: (String value) {
              setState(() {
                sortOption = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'none',
                child: Text('No Sort'),
              ),
              const PopupMenuItem(
                value: 'lowToHigh',
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: 'highToLow',
                child: Text('Price: High to Low'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () => showSearchDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('available', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var products = snapshot.data!.docs
              .map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return Product(
              id: doc.id,
              name: data['name'] ?? '',
              description: data['description'] ?? '',
              price: (data['price'] as num).toDouble(),
              sellerId: data['sellerId'] ?? '',
              imageUrl: data['imageUrl'],
              available: data['available'] ?? true,
            );
          })
              .where((product) =>
              product.name.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          products = sortProducts(products);

          return LayoutBuilder(
            builder: (context, constraints) {
              final double screenWidth = constraints.maxWidth;
              final int crossAxisCount = switch (screenWidth) {
                >= 1200 => 5,
                >= 900 => 4,
                >= 600 => 3,
                >= 400 => 2,
                _ => 1,
              };

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  Future<void> addToCart(BuildContext context, Product product) async {
    int quantity = 1; // Default quantity

    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int tempQuantity = 1;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Quantity"),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (tempQuantity > 1) {
                        setState(() {
                          tempQuantity--;
                        });
                      }
                    },
                  ),
                  Text(
                    "$tempQuantity",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        tempQuantity++;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, tempQuantity); // Return the selected product quantity
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );

    // Checks if any result, that is quantity, is returned
    if (result != null) {
      quantity = result; // Sets the selected quantity
      try {
        // Gets the current authenticated user
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String userId = user.uid;

          // Reference to Firestore collection where cart items are stored
          CollectionReference cart = FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('cart');

          // Add product to the cart (Firestore document)
          await cart.add({
            'productId': product.id,
            'price': product.price,
            'quantity': quantity,
            'totalPrice': product.price * quantity,
            'placedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Product added to cart!")),
          );
        } else {
          // kama user is not logged in,
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You need to be logged in to add products to the cart.")),
          );
        }
      } catch (e) {
        print("Failed to add product to cart: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add product to cart.")),
        );
      }
    }
  }

  void showProductDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.lightGreen, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: product.imageUrl != null
                        ? Image.network(
                      product.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.lightGreen,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Description:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : 'No description available',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                      ),
                      child: const Text('Close', style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showProductDetailsDialog(context),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product image inaingia hapa
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: AspectRatio(
                      aspectRatio: 1, // Square image
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          image: product.imageUrl != null
                              ? DecorationImage(
                            image: NetworkImage(product.imageUrl!),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: product.imageUrl == null
                            ? Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: constraints.maxWidth * 0.2,
                            color: Colors.grey[500],
                          ),
                        )
                            : null,
                      ),
                    ),
                  ),
                ),

                // Product details section
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Price and cart button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.lightGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () => addToCart(context, product),
                              icon: const Icon(Icons.shopping_cart),
                              color: Colors.lightGreen,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SellProductScreen extends StatefulWidget {
  const SellProductScreen({super.key});

  @override
  _SellProductScreenState createState() => _SellProductScreenState();
}

class _SellProductScreenState extends State<SellProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isLoading = false;

  // Image picking from phone storage --> sijaimplement hii
  // File? _imageFile;
  // final ImagePicker _picker = ImagePicker();

  // Future<void> _pickImage() async {
  //    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  //    if (pickedFile != null) {
  //      setState(() {
  //        _imageFile = File(pickedFile.path);
  //      });
  //    }
  //  }

  Future<void> _uploadProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Image upload
        // String? imageUrl;
        // if (_imageFile != null) {
        //    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        //    UploadTask uploadTask = FirebaseStorage.instance
        //        .ref('product_images/$fileName')
        //        .putFile(_imageFile!);
        //    TaskSnapshot snapshot = await uploadTask;
        //    imageUrl = await snapshot.ref.getDownloadURL();
        // }

        final price = double.tryParse(_priceController.text);
        if (price == null || price <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid positive price'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        await FirebaseFirestore.instance.collection('products').add({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': price,
          'sellerId': FirebaseAuth.instance.currentUser!.uid,
          'imageUrl': null, // Set to null since image upload is not functioning. Picha zinazoonekana kwenye app ni hardcoded URLs
          'available': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        // setState(() {
        //   _imageFile = null;
        // });

      } catch (e) {
        // Error handling
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell Your Product', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a product name';
                    }
                    if (value.trim().length < 3) {
                      return 'Product name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Product Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a product description';
                    }
                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a price';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid positive price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Image picker
                // _imageFile == null
                //     ? TextButton.icon(
                //         onPressed: _pickImage,
                //         icon: Icon(Icons.add_photo_alternate),
                //         label: Text('Pick Image'),
                //       )
                //     : Image.file(
                //         _imageFile!,
                //         height: 150,
                //       ),
                // SizedBox(height: 16),

                // Upload Button
                ElevatedButton(
                  onPressed: () {
                    // Check if user is logged in
                    User? currentUser = FirebaseAuth.instance.currentUser;

                    if (currentUser == null) {
                      // Show login required dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Login Required'),
                          content: const Text('You must be logged in to upload products.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: const Text('Go to Login'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // User is logged in, proceeds with upload
                      _isLoading ? null : _uploadProduct();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : const Text(
                    'Upload Product',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {

  // Fetch the cart data for the current user
  Future<List<ProductOrder>> fetchCart() async {
    // Retrieve user ID from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    // Debugging: Check if userId is null or empty
    print("Fetched userId from SharedPreferences: $userId");

    // Ensure userId is valid
    if (userId == null || userId.isEmpty) {
      print("Error: User ID not found or is empty in SharedPreferences");
      throw Exception("User ID not found in SharedPreferences");
    }

    // Reference to the Firebase Firestore collection for the cart
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId) // Dynamically use the retrieved user ID
        .collection('cart');

    try {
      // Fetch the cart items
      final snapshot = await cartRef.get();

      if (snapshot.docs.isNotEmpty) {
        // Map the documents to ProductOrder objects asynchronously
        List<Future<ProductOrder>> futures = snapshot.docs.map((doc) async {
          return await ProductOrder.fromFirestore(doc);  // Make sure to await the Future
        }).toList();

        // Wait for all futures to resolve
        return await Future.wait(futures);

      } else {
        // If no items found, return an empty list or throw an exception
        print("No items found in cart for userId: $userId");
        return [];
      }
    } catch (e) {
      print("Error fetching cart: $e");
      throw Exception("Failed to fetch cart items: $e");
    }
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity(BuildContext context, String cartItemId, int newQuantity) async {
    if (newQuantity < 1) {
      // Optionally handle invalid quantity (e.g., remove the item or prevent updates below 1)
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null || userId.isEmpty) {
      print("Error: User ID not found or is empty in SharedPreferences");
      throw Exception("User ID not found in SharedPreferences");
    }

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(cartItemId);

    try {
      // Fetch the product details (e.g., price) from the cart item
      final cartSnapshot = await cartRef.get();
      if (!cartSnapshot.exists) {
        print("Cart item not found: $cartItemId");
        return;
      }

      final data = cartSnapshot.data() as Map<String, dynamic>;
      final productPrice = data['price']; // Assuming Firestore stores the price

      // Recalculate total price
      final updatedTotalPrice = newQuantity * productPrice;

      // Update the cart item in Firestore
      await cartRef.update({
        'quantity': newQuantity,
        'totalPrice': updatedTotalPrice,
        'updatedAt': FieldValue.serverTimestamp(), // Update timestamp
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quantity updated!")),
      );

      // Refresh the UI
      setState(() {});
    } catch (e) {
      print("Error updating cart item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update quantity")),
      );
    }
  }

  // Delete cart item
  Future<void> deleteCartItem(BuildContext context, String cartItemId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    // Debugging: Check if userId is valid
    print("Deleting cart item for userId: $userId");

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId) // Replace with the actual user ID
        .collection('cart')
        .doc(cartItemId);

    await cartRef.delete();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item removed from cart!")));
    setState(() {});
  }

  Future<void> backfillTimestamps(String userId) async {
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart');

    final snapshot = await cartRef.get();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      if (data['placedAt'] == null) {
        await doc.reference.update({
          'placedAt': FieldValue.serverTimestamp(),
        });
      }

      if (data['updatedAt'] == null) {
        await doc.reference.update({
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  double calculateTotalPrice(List<ProductOrder> orders) {
    double total = 0.0;
    for (var order in orders) {
      total += order.totalPrice; // Access the totalPrice property
    }
    return total;
  }

  // Track order method (not implemented)
  void trackOrder(BuildContext context, String sellerId) {
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: SharedPreferences.getInstance().then((prefs) => prefs.getString('user_id')),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if user is logged in
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'My Cart',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: false,
              elevation: 1,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "You are not logged in.",
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      "Go to Login",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // User is logged in, fetch and display cart items
        return FutureBuilder<List<ProductOrder>>(
          future: fetchCart(),
          builder: (context, cartSnapshot) {
            if (cartSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (cartSnapshot.hasError) {
              return Center(child: Text("Error: ${cartSnapshot.error}"));
            }

            final orders = cartSnapshot.data ?? [];

            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'My Cart',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: false,
                elevation: 1,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
              ),
              body: FutureBuilder<List<ProductOrder>>(
                  future: fetchCart(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    // Using empty list if there is no data
                    final orders = snapshot.data ?? [];
                    print(orders);

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Items',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '\$${calculateTotalPrice(orders).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 20,

                                      fontWeight: FontWeight.bold,
                                      color: Colors.lightGreen.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              final product = order.product;

                              return Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    // Product image
                                    ClipRRect(
                                      borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(15),
                                      ),
                                      child: product.imageUrl != null
                                          ? Image.network(
                                        product.imageUrl!,
                                        width: 60,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            width: 80,
                                            height: 100,
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes !=
                                                    null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 120,
                                            height: 120,
                                            color: Colors.grey[200],
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              color: Colors.grey[500],
                                              size: 50,
                                            ),
                                          );
                                        },
                                      )
                                          : Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey[500],
                                          size: 50,
                                        ),
                                      ),
                                    ),

                                    // Product details
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),

                                            const SizedBox(height: 8),

                                            Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                // user anaincrease or decrease product quantity here
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey.shade300),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.remove, size: 20),
                                                        onPressed: () {
                                                          // Decrease quantity
                                                          updateCartItemQuantity(
                                                              context,
                                                              order.id,
                                                              order.quantity - 1
                                                          );
                                                        },
                                                      ),
                                                      Text(
                                                        '${order.quantity}',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.add, size: 20),
                                                        onPressed: () {
                                                          // Increase quantity
                                                          updateCartItemQuantity(
                                                              context,
                                                              order.id,
                                                              order.quantity + 1
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Price
                                                Text(
                                                  '\$${order.totalPrice.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.lightGreen.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 8),

                                            Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                // Remove products from cart
                                                TextButton.icon(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.redAccent,
                                                  ),
                                                  label: const Text(
                                                    'Remove',
                                                    style: TextStyle(color: Colors.redAccent),
                                                  ),
                                                  onPressed: () {
                                                    deleteCartItem(context, order.id);
                                                  },
                                                ),

                                                // Track order
                                                TextButton.icon(
                                                  icon: const Icon(
                                                    Icons.local_shipping_outlined,
                                                    color: Colors.blueAccent,
                                                  ),
                                                  label: const Text(
                                                    'Track',
                                                    style: TextStyle(
                                                        color: Colors.blueAccent),
                                                  ),
                                                  onPressed: () {
                                                    trackOrder(context, product.sellerId);
                                                  },
                                                ),
                                              ],
                                            ),
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

                        // Checkout
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: () {
                              // Checkout not implemented yet
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreen.shade600,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Proceed to Checkout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
              ),

            );
          },
        );
      },
    );
  }

}

class CartItem {
  final String id;
  final String productId;
  final int quantity;
  final double totalPrice;
  final DateTime? addedAt;

  CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.totalPrice,
    this.addedAt,
  });

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CartItem(
      id: doc.id,
      productId: data['productId'],
      quantity: data['quantity'],
      totalPrice: data['totalPrice'].toDouble(),
      addedAt: data['addedAt'] is Timestamp
          ? (data['addedAt'] as Timestamp).toDate()
          : null,

    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  AppUser? _user;
  bool _isLoading = true;
  String _location = "Fetching...";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      if (_location.isEmpty || _location == "Location Unavailable") {
        await _getLocation();
      }
    } catch (e) {
      _handleLocationError(e);
    }
  }

  Future<void> _getLocation() async {
    try {
      // location permission check
      LocationPermission permission = await Geolocator.checkPermission();

      // If permission is not granted, request it
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Handling denied permissions
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _updateLocationState("Location Permission Denied");
        return;
      }

      // Check if location services are enabled
      bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        _updateLocationState("Location Services Disabled");
        return;
      }

      // Attempt to get current position
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        _updateLocationState("Unable to Retrieve Location");
        return;
      }

      // Fetch placemarks
      List<Placemark> placemarks;
      try {
        placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        _updateLocationState("Address Lookup Failed");
        return;
      }

      // Process location details
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Collect non-null location components
        List<String?> locationParts = [
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country
        ].where((part) => part != null && part.isNotEmpty).toList();

        // Update location state
        _updateLocationState(
            locationParts.isNotEmpty
                ? locationParts.join(", ")
                : "Location Found"
        );
      } else {
        _updateLocationState("No Location Details Available");
      }
    } catch (e) {
      _handleLocationError(e);
    }
  }

  void _updateLocationState(String locationText) {
    setState(() {
      _location = locationText;
    });
  }

  void _handleLocationError(dynamic error) {
    print("Location Error: $error");
    _updateLocationState("Location Unavailable");
  }

  Future<void> _fetchUserData() async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        setState(() {
          _user = AppUser.fromFirestore(
              userDoc.data() as Map<String, dynamic>, firebaseUser.uid);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {

    if (_auth.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "You are not logged in.",
                style: TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "Go to Login",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }


    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildProfileStatsGrid(_user?.registeredAt),
            const SizedBox(height: 24),
            _buildProfileActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            _user != null && _user!.fullName != null
                ? _user!.fullName![0].toUpperCase()
                : 'G',
            style: const TextStyle(fontSize: 40.0),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_user?.fullName ?? 'User Name'),
            Text(_user?.email ?? 'user@example.com'),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileStatsGrid(DateTime? registeredAt) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5, // Reduced from 2 to prevent overflow
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard(
          icon: Icons.star_border,
          label: 'Seller Rating',
          value: '4.7/5',
        ),
        _buildStatCard(
          icon: Icons.shopping_bag_outlined,
          label: 'Total Sales',
          value: '42',
        ),
        _buildStatCard(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: _location,
        ),
        _buildStatCard(
          icon: Icons.calendar_today,
          label: 'Joined',
          value: registeredAt != null
              ? '${registeredAt.day} ${_getMonthName(registeredAt.month)} ${registeredAt.year}'
              : 'Unknown',
        ),
      ],
    );
  }


  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.lightGreen.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.lightGreen.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileActions(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.payment,
          label: 'Payment Methods',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () {
            // TODO: Implement notifications screen
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.settings_outlined,
          label: 'Account Settings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.lightGreen.shade100,
        foregroundColor: Colors.lightGreen.shade700,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String sellerId;
  final String? imageUrl;
  final bool available;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.sellerId,
    this.imageUrl,
    required this.available,
  });
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _privacyModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _privacyModeEnabled = prefs.getBool('privacyMode') ?? false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'App Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSettingsSection(
              title: 'Appearance',
              children: [
                _buildSettingsToggle(
                  title: 'Dark Mode',
                  subtitle: 'Switch between light and dark themes',
                  value: _isDarkMode,
                  onChanged: (bool value) {
                    setState(() {
                      _isDarkMode = value;
                    });
                    _savePreference('darkMode', value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSettingsSection(
              title: 'Notifications',
              children: [
                _buildSettingsToggle(
                  title: 'Enable Notifications',
                  subtitle: 'Receive alerts for new messages and updates',
                  value: _notificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _savePreference('notifications', value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSettingsSection(
              title: 'Privacy',
              children: [
                _buildSettingsToggle(
                  title: 'Privacy Mode',
                  subtitle: 'Hide sensitive information',
                  value: _privacyModeEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _privacyModeEnabled = value;
                    });
                    _savePreference('privacyMode', value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.lightGreen.shade700,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildSettingsToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.lightGreen.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.lightGreen.shade600,
          ),
        ],
      ),
    );
  }
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  _PaymentMethodsScreenState createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  // List of payment methods
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      icon: Icons.credit_card,
      name: 'Credit/Debit Card',
      description: 'Visa, Mastercard, etc.',
      isConnected: false,
    ),
    PaymentMethod(
      icon: Icons.account_balance,
      name: 'Bank Transfer',
      description: 'Direct bank account payment',
      isConnected: false,
    ),
    PaymentMethod(
      icon: Icons.phone_android,
      name: 'Tigo Pesa',
      description: 'Mobile Money (Tanzania)',
      isConnected: false,
    ),
    PaymentMethod(
      icon: Icons.phone_android,
      name: 'Airtel Money',
      description: 'Mobile Money (Multiple Countries)',
      isConnected: false,
    ),
    PaymentMethod(
      icon: Icons.phone_android,
      name: 'M-Pesa',
      description: 'Mobile Money (Kenya, Tanzania)',
      isConnected: false,
    ),
    PaymentMethod(
      icon: Icons.phone_android,
      name: 'MTN Mobile Money',
      description: 'Mobile Money (Multiple African Countries)',
      isConnected: false,
    ),
    PaymentMethod(
      icon: Icons.payment,
      name: 'PayPal',
      description: 'Online Payment Platform',
      isConnected: false,
    ),
    PaymentMethod(
      icon: Icons.payments_outlined,
      name: 'Google Pay',
      description: 'Google Payment Service',
      isConnected: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Methods',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Payment Methods',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.lightGreen.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select and manage your preferred payment methods',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ..._paymentMethods.map((method) => _buildPaymentMethodTile(method)).toList(),
            const SizedBox(height: 24),
            _buildAddNewMethodButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: method.isConnected ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          method.icon,
          color: method.isConnected ? Colors.green.shade600 : Colors.grey.shade600,
        ),
        title: Text(
          method.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: method.isConnected ? Colors.green.shade700 : Colors.black,
          ),
        ),
        subtitle: Text(
          method.description,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: CupertinoSwitch(
          value: method.isConnected,
          onChanged: (bool value) {
            _showPaymentMethodDialog(method);
          },
          activeColor: Colors.lightGreen.shade600,
        ),
      ),
    );
  }

  Widget _buildAddNewMethodButton() {
    return ElevatedButton.icon(
      onPressed: _showAddPaymentMethodBottomSheet,
      icon: const Icon(Icons.add),
      label: const Text('Add New Payment Method'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.lightGreen.shade100,
        foregroundColor: Colors.lightGreen.shade700,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showPaymentMethodDialog(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Payment Method'),
          content: Text('Do you want to ${method.isConnected ? 'disconnect' : 'connect'} ${method.name}?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                setState(() {
                  method.isConnected = !method.isConnected;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddPaymentMethodBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Payment Method',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16, // Adjust the font size to a reasonable value
                  fontWeight: FontWeight.bold,
                  color: Colors.lightGreen.shade700,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.phone_android),
                title: const Text('Add Mobile Money'),
                onTap: () {
                  // TODO: Implement mobile money addition
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Add Credit/Debit Card'),
                onTap: () {
                  // TODO: Implement card addition
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: const Text('Add Bank Account'),
                onTap: () {
                  // TODO: Implement bank account addition
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class PaymentMethod {
  final IconData icon;
  final String name;
  final String description;
  bool isConnected;

  PaymentMethod({
    required this.icon,
    required this.name,
    required this.description,
    this.isConnected = false,
  });
}