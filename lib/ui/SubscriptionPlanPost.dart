import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../ui/NotificationScreen.dart';

class SubscriptionPlanPost extends StatefulWidget {
  const SubscriptionPlanPost({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlanPost> createState() => _SubscriptionPlanPostState();
}

class _SubscriptionPlanPostState extends State<SubscriptionPlanPost> {
  final Color mcdonaldsRed = const Color(0xFFDA291C);
  String? selectedPlan;
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  String? activePlanId;

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
  }

  Future<void> _loadCurrentSubscription() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Loading subscription for user: ${user.uid}');
        
        final docSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          final subscriptionData = docSnapshot.data()?['subscription'];
          print('Raw subscription data: $subscriptionData');
          
          if (subscriptionData != null && subscriptionData['status'] == 'active') {
            setState(() {
              activePlanId = subscriptionData['planId'].toString();
              print('Set activePlanId to: "$activePlanId"');
            });
          } else {
            print('Subscription data is null or not active');
          }
        } else {
          print('Document does not exist');
        }
      } else {
        print('No user logged in');
      }
    } catch (e) {
      print('Error loading subscription: $e');
      print('Error stack trace: ${StackTrace.current}');
    }
  }

  String getBaseUrl() {
    // Check if running in debug mode
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      if (Platform.isAndroid) {
        return 'http://192.168.100.31:4000'; // Your computer's IP address
      } else if (Platform.isIOS) {
        return 'http://192.168.100.31:4000'; // Your computer's IP address
      }
      return 'http://192.168.100.31:4000'; // Local development
    }
    
    // Production URL
    return 'https://your-production-server.com'; // Replace with actual production URL
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 40) / 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alege Abonamentul',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFDA291C),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Status: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: activePlanId != null ? Colors.green.shade100 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: activePlanId != null ? Colors.green : Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getSubscriptionStatus(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: activePlanId != null ? Colors.green.shade800 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Selectează Planul de Abonament',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDA291C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Alege un plan de abonament pentru a-ți prezenta serviciile și produsele. Profilul tău va fi vizibil potențialilor clienți, ajutându-te să-ți dezvolți afacerea.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSubscriptionCard(
                    months: '3',
                    price: '120',
                    features: [
                      'Suport de Bază',
                      'Acces Complet',
                      'Vizibilitate Profil (3 Luni)',
                      'Ranking de Bază în Căutări'
                    ],
                    isPopular: false,
                    width: cardWidth,
                    isSelected: selectedPlan == '3',
                    onSelect: () => setState(() => selectedPlan = '3'),
                  ),
                  const SizedBox(width: 16),
                  _buildSubscriptionCard(
                    months: '6',
                    price: '240',
                    features: [
                      'Suport Prioritar',
                      'Acces Complet',
                      'Vizibilitate Profil (6 Luni)',
                      'Ranking Îmbunătățit în Căutări',
                      'Engagement Profil Mai Bun'
                    ],
                    isPopular: true,
                    width: cardWidth,
                    isSelected: selectedPlan == '6',
                    onSelect: () => setState(() => selectedPlan = '6'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: _buildSubscriptionCard(
                  months: '12',
                  price: '480',
                  features: [
                    'Suport Premium',
                    'Acces Complet',
                    'Vizibilitate Profil (12 Luni)',
                    'Prioritate în Rezultatele Căutării',
                    'Cel Mai Bun Engagement al Profilului',
                    'Algoritm Avansat de Căutare'
                  ],
                  isPopular: false,
                  width: cardWidth * 1.05,
                  isSelected: selectedPlan == '12',
                  onSelect: () => setState(() => selectedPlan = '12'),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Promovează-ți Contul pe Pagina Principală',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDA291C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Apari pe pagina principală și crește-ți vizibilitatea cu pachetele noastre de promovare.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSubscriptionCard(
                    months: '14 Days',
                    price: '45',
                    features: [
                      'Listare Promovată pe Pagina Principală',
                      'Prioritate în Rezultatele Căutării',
                      'Vizibilitate Îmbunătățită'
                    ],
                    isPopular: false,
                    width: cardWidth,
                    isSelected: selectedPlan == 'promo14',
                    onSelect: () => setState(() => selectedPlan = 'promo14'),
                  ),
                  const SizedBox(width: 16),
                  _buildSubscriptionCard(
                    months: '30 Days',
                    price: '85',
                    features: [
                      'Extinderea Listării de Pe Pagina Principală',
                      'Prioritate în Rezultatele Căutării',
                      'Expunerea Maximă a Profilului'
                    ],
                    isPopular: true,
                    width: cardWidth,
                    isSelected: selectedPlan == 'promo30',
                    onSelect: () => setState(() => selectedPlan = 'promo30'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Promovează-ți Contul în Categorie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDA291C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Apari în categoria ta de business și crește-ți vizibilitatea cu pachetele noastre de promovare.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSubscriptionCard(
                    months: '14 Days',
                    price: '35',
                    features: [
                      'Listare Promovată în Categorie',
                      'Prioritate în Rezultatele Căutării',
                      'Vizibilitate Îmbunătățită'
                    ],
                    isPopular: false,
                    width: cardWidth,
                    isSelected: selectedPlan == 'catpromo14',
                    onSelect: () => setState(() => selectedPlan = 'catpromo14'),
                  ),
                  const SizedBox(width: 16),
                  _buildSubscriptionCard(
                    months: '30 Days',
                    price: '75',
                    features: [
                      'Extinderea Listării de Pe Categorie',
                      'Prioritate în Rezultatele Căutării',
                      'Expunerea Maximă a Categoriei'
                    ],
                    isPopular: true,
                    width: cardWidth,
                    isSelected: selectedPlan == 'catpromo30',
                    onSelect: () => setState(() => selectedPlan = 'catpromo30'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubscriptionStatus() {
    if (activePlanId == null) {
      return 'Fără Abonament';
    }
    
    switch(activePlanId) {
      case '3':
        return 'Plan 3 Luni';
      case '6':
        return 'Plan 6 Luni';
      case '12':
        return 'Plan 12 Luni';
      default:
        return 'Plan Necunoscut';
    }
  }

  Future<void> handlePayment(String planId, String amount) async {
    print('Starting payment process for planId: $planId');
    
    try {
      setState(() {
        _isLoading = true;
      });

      // Convert string amount to double first
      final amountDouble = double.parse(amount);
      // Convert to smallest currency unit (bani)
      final amountInBani = (amountDouble * 100).toInt();
      
      print('Original amount: $amount RON');
      print('Amount in bani: $amountInBani');

      final url = '${getBaseUrl()}/create-payment-intent';
      print('Making request to: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amountInBani,
          'currency': 'ron',
        }),
      );

      print('Server response status: ${response.statusCode}');
      print('Server response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Payment server error: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);
      final clientSecret = jsonResponse['clientSecret'];

      // Initialize the payment sheet with the correct amount display
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Your App Name',
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: const Color(0xFFDA291C),
            ),
          ),
          // Add these parameters to ensure correct amount display
          billingDetails: const BillingDetails(),
          primaryButtonLabel: 'Pay ${amount} RON',
        ),
      );

      // Present the payment sheet
      await Stripe.instance.presentPaymentSheet();

      // After successful payment
      if (mounted) {
        print('Payment successful, updating Firestore...');
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('No user logged in');
        }
        
        // Determine which type of update to perform
        if (planId.startsWith('promo')) {
          print('Updating homepage promotion...');
          await _updatePromotion(planId);
        } else if (planId.startsWith('catpromo')) {
          print('Updating category promotion...');
          await _updateCategoryPromotion(planId);
        } else if (['3', '6', '12'].contains(planId)) {
          print('Updating subscription...');
          await _updateSubscription(planId);
        }

        // Increment unreadNotifications
        final userRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
        await userRef.update({
          'unreadNotifications': FieldValue.increment(1),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      print('Error in handlePayment: $e');
      if (e is StripeException) {
        if (e.error.message?.contains('Payment canceled') == true) {
          print('Payment canceled by user');
          return;
        }
      }
      print('Payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StripeException 
                  ? e.error.message ?? 'Payment failed'
                  : 'An error occurred during payment',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSubscription(String planId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Error: No user logged in');
        return;
      }

      print('Attempting to update subscription for user: ${user.uid}');
      print('Plan ID: $planId');

      // Only process main subscription plans
      if (!['3', '6', '12'].contains(planId)) {
        print('Not a main subscription plan'); 
        return;
      }

      // Calculate end date based on plan duration
      DateTime now = DateTime.now().toUtc();
      DateTime endDate;
      String planType;
      
      switch(planId) {
        case '3':
          endDate = now.add(const Duration(days: 90));
          planType = 'basic';
          break;
        case '6':
          endDate = now.add(const Duration(days: 180));
          planType = 'standard';
          break;
        case '12':
          endDate = now.add(const Duration(days: 365));
          planType = 'premium';
          break;
        default:
          return;
      }

      print('Plan ID: $planId');
      print('Calculated end date: $endDate');

      // Reference to the user document
      final userRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);

      // Check if the document exists
      final docSnapshot = await userRef.get();
      
      if (!docSnapshot.exists) {
        print('Creating new user document');
        // Create the document if it doesn't exist
        await userRef.set({
          'email': user.email,
          'uid': user.uid,
          'createdAt': Timestamp.now(),
        });
      }

      // Prepare subscription data
      final subscriptionData = {
        'subscription': {
          'planId': planId,
          'planType': planType,
          'startDate': Timestamp.now(),
          'endDate': Timestamp.fromDate(endDate),
          'status': 'active',
          'canPost': true,
        }
      };

      print('Updating with subscription data: $subscriptionData');

      // Update user subscription in Firestore
      await userRef.set(subscriptionData, SetOptions(merge: true));

      print('Subscription updated successfully');
      
      // Verify the update
      final updatedDoc = await userRef.get();
      print('Updated document data: ${updatedDoc.data()}');

    } catch (e) {
      print('Error updating subscription: $e');
      print('Error stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> _updateCategoryPromotion(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user found for category promotion update');
      return;
    }

    print('Updating category promotion for user: ${user.uid}');
    
    try {
      final userRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid);

      // Calculate promotion duration
      final days = planId == 'catpromo14' ? 14 : 30;
      final now = DateTime.now().toUtc();
      final endDate = now.add(Duration(days: days));

      // Create new promotion entry
      final newPromotion = {
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(endDate),
        'purchasedAt': Timestamp.now(),
        'status': 'active',
      };

      print('New promotion data: $newPromotion');

      // First, get the current document
      final docSnapshot = await userRef.get();
      
      if (docSnapshot.exists) {
        print('Existing user document found');
        final data = docSnapshot.data() as Map<String, dynamic>;
        List<dynamic> currentPromotions = List.from(data['category_promotions'] ?? []);
        
        currentPromotions.add(newPromotion);
        
        print('Updating with promotions: $currentPromotions');
        
        await userRef.update({
          'category_promotions': currentPromotions,
        });
      } else {
        print('Creating new user document');
        await userRef.set({
          'email': user.email,
          'uid': user.uid,
          'category_promotions': [newPromotion],
        }, SetOptions(merge: true));
      }

      // Verify the update
      final verifyDoc = await userRef.get();
      print('Updated document data: ${verifyDoc.data()}');

    } catch (e) {
      print('Error updating category promotion: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> _updatePromotion(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user found for homepage promotion update');
      return;
    }

    print('Updating homepage promotion for user: ${user.uid}');
    
    try {
      final userRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid);

      // Calculate promotion duration
      final days = planId == 'promo14' ? 14 : 30;
      final now = DateTime.now().toUtc();
      final endDate = now.add(Duration(days: days));

      // Create new promotion entry
      final newPromotion = {
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(endDate),
        'purchasedAt': Timestamp.now(),
        'status': 'active',
      };

      print('New promotion data: $newPromotion');

      // First, get the current document
      final docSnapshot = await userRef.get();
      
      if (docSnapshot.exists) {
        print('Existing user document found');
        final data = docSnapshot.data() as Map<String, dynamic>;
        List<dynamic> currentPromotions = List.from(data['homepage_promotions'] ?? []);
        
        currentPromotions.add(newPromotion);
        
        print('Updating with promotions: $currentPromotions');
        
        await userRef.update({
          'homepage_promotions': currentPromotions,
        });
      } else {
        print('Creating new user document');
        await userRef.set({
          'email': user.email,
          'uid': user.uid,
          'homepage_promotions': [newPromotion],
        }, SetOptions(merge: true));
      }

      // Verify the update
      final verifyDoc = await userRef.get();
      print('Updated document data: ${verifyDoc.data()}');

    } catch (e) {
      print('Error updating homepage promotion: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Widget _buildSubscriptionCard({
    required String months,
    required String price,
    required List<String> features,
    required bool isPopular,
    required double width,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    // Extract the plan ID for subscription plans
    String planId = months.replaceAll(' Months', '').replaceAll(' Days', '');
    
    // Check if this is a main subscription plan (3, 6, or 12 months)
    bool isMainSubscription = ['3', '6', '12'].contains(planId);
    
    // Only check for active status on main subscription plans
    bool isActive = isMainSubscription && activePlanId == planId;
    
    print('Card Details:');
    print('- Months: $months');
    print('- PlanId: $planId');
    print('- ActivePlanId: $activePlanId');
    print('- IsMainSubscription: $isMainSubscription');
    print('- IsActive: $isActive');

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFDA291C) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFDA291C).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDA291C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              months.contains('Days') ? months : '$months Luni',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPopular ? const Color(0xFFDA291C) : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$price RON',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isPopular ? const Color(0xFFDA291C) : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: isPopular ? const Color(0xFFDA291C) : Colors.green,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular 
                      ? const Color(0xFFDA291C)
                      : Colors.grey.shade100,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading 
                    ? null 
                    : () {
                        if (selectedPlan == null) {
                          print('No plan selected');
                          return;
                        }
                        print('Selected plan: $selectedPlan, Price: $price');
                        handlePayment(selectedPlan!, price);
                      },
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        months.contains('Days') ? 'Cumpără Acum' : 'Abonează-te Acum',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPopular ? Colors.white : Colors.black87,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
