import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'authscreen.dart';
import 'MainNavigationScreen.dart';

// Models
class AppUser {
  final String uid;
  final String email;
  final String? phoneNumber;
  final String? fullName;
  final DateTime? registeredAt;

  AppUser({
    required this.uid,
    required this.email,
    this.phoneNumber,
    this.fullName,
    this.registeredAt,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      fullName: data['fullName'],
      registeredAt: data['registeredAt'] != null
          ? (data['registeredAt'] as Timestamp).toDate()
          : null,
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
    this.available = true,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      sellerId: data['sellerId'] ?? '',
    );
  }
}

class ProductOrder {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final int quantity;
  final double totalPrice;
  final String status;
  final DateTime placedAt;
  final DateTime? updatedAt;
  final Product product;

  ProductOrder({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.quantity,
    required this.totalPrice,
    this.status = 'in_cart',
    required this.placedAt,
    this.updatedAt,
    required this.product,
  });

  // Fetching product for a given productId
  static Future<Product> fetchProduct(String productId) async {
    final productSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();

    if (productSnapshot.exists) {
      return Product.fromFirestore(productSnapshot);
    } else {
      throw Exception("Product not found");
    }
  }

  // Converting Firestore document to ProductOrder
  static Future<ProductOrder> fromFirestore(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    // Fetching the product using the fetchProduct method
    final product = await fetchProduct(data['productId'] ?? '');

    return ProductOrder(
      id: doc.id,
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      productId: data['productId'] ?? '',
      quantity: data['quantity'] ?? 0,
      totalPrice: data['totalPrice']?.toDouble() ?? 0.0,
      status: data['status'] ?? 'in_cart',
      placedAt: data['placedAt'] is Timestamp
          ? (data['placedAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      product: product,  // the fetched product is assigned here
    );
  }

  @override
  String toString() {
    return 'ProductOrder(totalPrice: $totalPrice)';
  }
}

// Authentication service
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser?> registerUser({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Getting current timestamp for registration records
        DateTime registrationTime = DateTime.now();

        // Update the user's display name from guest to the actual user's name
        await result.user!.updateDisplayName(fullName);

        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'fullName': fullName,
          'phoneNumber': phoneNumber ?? '',
          'registeredAt': registrationTime,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return AppUser(
          uid: result.user!.uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          registeredAt: registrationTime,
        );
      }
      return null;
    } catch (e) {
      print("Registration error: $e");
      return null;
    }
  }


  Future<AppUser?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        DocumentSnapshot userData = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();

        // Stores the user ID in SharedPreferences after successful login ili itumike during navigation to other screens.
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('user_id', result.user!.uid);

        return AppUser.fromFirestore(
          userData.data() as Map<String, dynamic>,
          result.user!.uid,
        );
      }
      return null;
    } catch (e) {
      print("Sign in error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

// App entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MazaoApp());
}

class MazaoApp extends StatefulWidget {
  static _MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>();
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MazaoApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Katalog',
      theme: ThemeData(

        primaryColor: Colors.green,

        scaffoldBackgroundColor: isDarkMode ? const Color(0xFF414A4C) : Colors.grey.shade100,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        appBarTheme: AppBarTheme(
          color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          titleTextStyle: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.greenAccent,
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
          labelStyle: const TextStyle(color: Colors.green),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
        ),

        textTheme: TextTheme(
          bodyLarge: TextStyle(color: isDarkMode ? Colors.black : Colors.black87, fontSize: 16),
          bodyMedium: TextStyle(color: isDarkMode ? Colors.black : Colors.black54, fontSize: 14),
          titleLarge: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),

        colorScheme: ColorScheme.fromSwatch().copyWith(
          surface: isDarkMode ? Colors.black : Colors.grey.shade100,
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
          primary: Colors.green,
          secondary: Colors.lightGreenAccent,
        ),
      ),


      initialRoute: '/home',
      routes: {
        '/bills': (context) => const PaymentMethodsScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => const MainNavigationScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/cart': (context) => CartScreen(),
        '/products': (context) => ProductListScreen(),
      },
    );
  }
}