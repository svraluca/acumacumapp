import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:direct_select/direct_select.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:translator/translator.dart';

import 'package:acumacum/ui/HomePage.dart';
import 'package:acumacum/ui/Locations_Search.dart';

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  _BusinessPageState createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  String? userId;
  var streat;
  var country;
  var locality;
  var postelCode;
  var category;

  final _formKey = GlobalKey<FormState>();

  int selectedIndex1 = 0;
  int selectedIndex2 = 5;
  int selectedIndex3 = 8;

  TextEditingController controller = TextEditingController();

  final Map<String, List<String>> categoriesWithSubcategories = {
    "Agricultura": [
   "Agricultura ecologica",
      "Apicultură",
      "Consultanta agricola",
      "Servicii de irigatii"
    ],
    "Animale": [
      "Veterinar",
      "Pet shop",
      "Dog walking",
      "Pet sitting",
      "Dresaj",
      "Toaletaj",
      "Pensiune animale"
    ],
    "Auto": [
      "Mecanică auto",
      "Vulcanizare",
      "Spălătorie auto",
      "Tinichigerie",
      "Electrician auto",
      "Transport marfă",
      "Tractări auto",
      "Închirieri auto"
    ],
    "Artistice": [
      "Pictură",
      "Sculptură",
      "Fotografie",
      "Design grafic",
      "Muzică",
      "Dans",
      "Teatru",
      "Artizanat"
    ],

    "Saloane si Frizerii": [
      "Coafor",
      "Frizerie",
      "Beauty",
      "Manichiură",
      "Pedichiură",
      "Masaj",
      "Tratamente faciale",
      "Epilare"
    ],
    "Constructii": [
      "Amenajări interioare",
      "Zugrăveli",
      "Instalații sanitare",
      "Tâmplărie",
      "Pardoseli",
      "Acoperiș",
      "Zidărie",
      "Design interior"
    ],
    "Curatenie": [
      "Curățenie apartamente",
      "Curățenie birouri",
      "Curățenie industrială",
      "Curățare covoare",
      "Curățare canapele",
      "Dezinfecție",
      "Curățenie după constructor"
    ],
    "Consultanta": [
      "Consultanță afaceri",
      "Consultanță financiară",
      "Consultanță juridică",
      "Consultanță HR",
      "Consultanță marketing",
      "Consultanță IT",
      "Planificare strategică",
      "Dezvoltare Personala",
     "Consultanță energie verde",
    ],
    "Electrice": [
      "Instalații electrice",
      "Reparații electrice",
      "Tablouri electrice",
      "Iluminat",
      "Automatizări",
      "Sisteme securitate",
      "Mentenanță",
      "Panouri solare",
      "Reciclare",
      "Audit energetic",
      "Sisteme încălzire",
      "Pompe de căldură",
      "Izolații termice"
    ],

    "Educatie": [
      "Meditații",
      "Cursuri limbi străine",
      "Training corporativ",
      "After school",
      "Cursuri IT",
      "Dezvoltare profesională",
      "Workshop-uri"
    ],
    "Evenimente": [
   
      "Decorațiuni",
      "Catering evenimente",
      "Planificare evenimente",
      "Funerare",
    ],

    "Finante si Asigurari": [
      "Contabilitate",
      "Asigurări auto",
      "Asigurări locuințe",
      "Credite",
      "Consultanță fiscală",
      "Audit financiar",
      "Planificare financiară"
    ],
    "Fitness": [
      "Personal trainer",
      "Yoga",
      "Pilates",
      "Aerobic",
      "Nutriție",
      "CrossFit",
      "Antrenamente online"
    ],
    "Freelancing": [
      "Copywriting",
      "Web design",
      "Social media",
      "Traduceri",
      "Content creation",
      "SEO",
      "Virtual assistant"
    ],
    "Amenajari Exterioare": [
      "Grădinărit",
      "Peisagistică",
      "Sisteme irigații",
      "Întreținere spații verzi",
      "Tuns gazon",
      "Decorațiuni exterior",
    ],
    "Instalatii": [
      "Instalații sanitare",
      "Instalații termice",
      "Instalații gaz",
      "Centrale termice",
      "Canalizare",
      "Desfundare",
      "Mentenanță"
    ],
    "Sanatate si Medical": [
      "Medicină generală",
      "Pediatrie",
      "Dermatologie",
      "Stomatologie",
      "Fizioterapie",
      "Kinetoterapie",
      "Psihologie",
      "Nutriție",
      "Recuperare medicală"
    ],
    "Legal si Constultanta": [
      "Avocat",
      "Notar",
      "Mediator",
      "Executor judecătoresc",
      "Consultanță juridică",
      "Proprietate intelectuală",
      "Drept comercial"
    ],
    "Logistica": [
      "Transport marfă",
      "Curierat",
      "Depozitare",
      "Ambalare",
      "Distribuție",
      "Inventariere",
      "Supply chain"
    ],
    "Turism": [
      "Ghid turistic",
      "Agenție turism",
      "Transport turistic",
      "Turism rural",
      "Evenimente turistice",
      "Turism de aventură"
    ],
    "Marketing": [
      "Social media marketing",
      "SEO",
      "Content marketing",
      "Email marketing",
      "Branding",
      "Publicitate online",
      "Strategii marketing"
    ],
  
    "Familie": [
      "Babysitting",
      "Îngrijire bătrâni",
      "Menaj",
      "Meditații copii",
      "Consiliere familie",
      "After school"
    ],
    "Media": [
      "Fotografie",
      "Videografie",
      "Producție audio",
      "Relații publice",
      "Copywriting",
      "Social media",
      "Podcast"
    ],
    "Ajutor Personal": [
      "Ospatar",
      "Barman",
      "Bucatar",
      "Tamplar",
      "Sofer",
      "Ambalator Manual",
      "Culegator Fructe/Legume",
      "Ingrijitor",
        "Croitor",
      "Pantofar",
      "Tabacar/Marochiner",
      "Tapiter",
    ],


  };

  final List<String> timeSlots = List.generate(24, (index) {
    String hour = index.toString().padLeft(2, '0');
    return '$hour:00';
  });

  LocationPermission permission = LocationPermission.denied;

  List<bool> selectedDays = List.filled(7, false); // Represents Mon to Sun
  final List<String> daysOfWeek = ['Lun', 'Mar', 'Mie', 'Joi', 'Vin', 'Sâm', 'Dum'];

  TimeOfDay? selectedOpenTime;
  TimeOfDay? selectedCloseTime;

  final List<String> romanianCities = [
    "Adjud", "Alba Iulia", "Alexandria", "Arad", "Avrig",
    "Bacău", "Baia Mare", "Băicoi", "Băilești", "Bălan",
    "Balș", "Bârlad", "Beiuș", "Bistrița", "Blaj",
    "Bolintin-Vale", "Borșa", "Botoșani", "Bragadiru", "Brăila",
    "Brașov", "Breaza", "București", "Buftea", "Buhuși",
    "Buzău", "Calafat", "Călărași", "Călan", "Câmpia Turzii",
    "Câmpina", "Câmpulung", "Caracal", "Caransebeș", "Carei",
    "Cernavodă", "Chișineu-Criș", "Cluj-Napoca", "Codlea", "Comănești",
    "Constanța", "Corabia", "Covasna", "Craiova", "Curtea de Argeș",
    "Dej", "Deva", "Dorohoi", "Drăgășani", "Drobeta-Turnu Severin",
    "Făgăraș", "Făget", "Fetești", "Filiași", "Focșani",
    "Galați", "Găești", "Gheorgheni", "Gherla", "Giurgiu",
    "Hârlău", "Hunedoara", "Huși", "Iași", "Lugoj",
    "Lupeni", "Măcin", "Măgurele", "Mangalia", "Marghita",
    "Mărășești", "Medgidia", "Mediaș", "Miercurea Ciuc", "Mioveni",
    "Mizil", "Moreni", "Motru", "Năvodari", "Negrești-Oaș",
    "Odorheiu Secuiesc", "Oltenița", "Oradea", "Orăștie", "Oravița",
    "Orșova", "Ovidiu", "Pantelimon", "Pașcani", "Pecica",
    "Petrila", "Petroșani", "Piatra Neamț", "Pitești", "Ploiești",
    "Popești-Leordeni", "Pucioasa", "Rădăuți", "Râmnicu Sărat", "Râmnicu Vâlcea",
    "Reghin", "Reșița", "Roman", "Roșiorii de Vede", "Săcele",
    "Salonta", "Satu Mare", "Sebeș", "Sfântu Gheorghe", "Sighetu Marmației",
    "Sighișoara", "Șimleu Silvaniei", "Slatina", "Slobozia", "Suceava",
    "Târgoviște", "Târgu Jiu", "Târgu Mureș", "Târgu Neamț", "Târgu Ocna",
    "Târgu Secuiesc", "Târnăveni", "Tecuci", "Timișoara", "Toplița",
    "Tulcea", "Turda", "Turnu Măgurele", "Țăndărei", "Urziceni",
    "Vaslui", "Vișeu de Sus", "Voluntari", "Vulcan", "Zalău",
    "Zărnești", "Zimnicea"
  ]..sort();

  String? selectedCity;
  String? selectedCategory;
  String? selectedSubcategory;

  @override
  void initState() {
    userId = FirebaseAuth.instance.currentUser!.uid;
    super.initState();
    getLocationPermission();
    fetchSubcategory();
  }

  void getLocationPermission() async {
    permission = await Geolocator.requestPermission();
  }

  void fetchSubcategory() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('BusinessAccount')
          .doc('detail')
          .get();

      if (doc.exists) {
        setState(() {
          selectedSubcategory = doc['category'];
        });
      }
    } catch (e) {
      print('Error fetching subcategory: $e');
    }
  }

  String getSelectedDaysString() {
    List<String> selectedDaysList = [];
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) {
        selectedDaysList.add(daysOfWeek[i]);
      }
    }
    return selectedDaysList.join(', ');
  }

  List<Widget> _buildItems1() {
    return categoriesWithSubcategories.values
        .expand((list) => list)
        .toList()
        .map((val) => MySelectionItem(title: val))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Stack(children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Center(
              child: OverflowBox(
                maxWidth: double.infinity,
                child: Transform.translate(
                  offset: const Offset(200, 100),
                  //  child: Image.asset(
                  //  '',
                  // fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          // ImageFiltered(
          //     imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          //     child: const RiveAnimation.asset(
          //         '')),
          SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Text(
                        'acumacum',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'SignPainter',
                          fontSize: 45,
                        ),
                      ),
                    )),
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
//                  Padding(
//                    padding: const EdgeInsets.only(
//                        left: 40.0, right: 40.0, top: 40.0),
//                    child: TextFormField(
//                      validator: (val) =>
//                      val.isEmpty ? 'Enter street' : null,
//                      onChanged: (val) {
//                        setState(() => streat = val);
//                      },
//                      style: TextStyle(color: Colors.black),
//                      decoration: InputDecoration(
//                          hintText: 'Enter street',
//                          hintStyle: TextStyle(
//                              fontFamily: 'Antra',
//                              fontSize: 12.0,
//                              color: Colors.black)),
//                    ),
//                  ),
//                  SizedBox(height: 10),
//                  Padding(
//                    padding: const EdgeInsets.only(
//                        left: 40.0, right: 40.0, top: 40.0),
//                    child: TextFormField(
//                      validator: (val) =>
//                          val.isEmpty ? 'Postal Code' : null,
//                      onChanged: (val) {
//                        setState(() => postelCode = val);
//                      },
//                      style: TextStyle(color: Colors.black),
//                      decoration: InputDecoration(
//                          hintText: 'PostalCode',
//                          hintStyle: TextStyle(
//                              fontFamily: 'Antra',
//                              fontSize: 12.0,
//                              color: Colors.black)),
//                    ),
//                  ),
//                  Padding(
//                    padding: const EdgeInsets.only(
//                        left: 40.0, right: 40.0, top: 40.0),
//                    child: TextFormField(
//                      validator: (val) => val.isEmpty ? 'Locality' : null,
//                      onChanged: (val) {
//                        setState(() => locality = val);
//                      },
//                      style: TextStyle(color: Colors.black),
//                      decoration: InputDecoration(
//                          hintText: 'Locality',
//                          hintStyle: TextStyle(
//                              fontFamily: 'Antra',
//                              fontSize: 12.0,
//                              color: Colors.black)),
//                    ),
//                  ),
//                  SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 40.0, right: 40.0, top: 40.0),
                        child: GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LocationSearch()),
                            );
                            
                            if (result != null) {
                              setState(() {
                                selectedCity = result;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              hintText: 'Selectează orașul',
                              hintStyle: TextStyle(
                                fontFamily: 'Antra',
                                fontSize: 12.0,
                                color: Colors.black,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            child: Text(
                              selectedCity ?? 'Selectează orașul',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

//                  Padding(
//                    padding: const EdgeInsets.only(
//                        left: 40.0, right: 40.0, top: 40.0),
//                    child: TextFormField(
//                      validator: (val) => val.isEmpty ? 'Category' : null,
//                      onChanged: (val) {
//                        setState(() => category = val);
//                      },
//                      style: TextStyle(color: Colors.black),
//                      decoration: InputDecoration(
//                          hintText: 'Category',
//                          hintStyle: TextStyle(
//                              fontFamily: 'Antra',
//                              fontSize: 12.0,
//                              color: Colors.black)),
//                    ),
//                  ),

                      Padding(
                        padding: const EdgeInsets.only(left: 40.0, right: 40.0, top: 20.0),
                        child: Column(
                          children: [
                            // Category Dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Categorie',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                              ),
                              value: selectedCategory,
                              hint: const Text('Selectează categoria'),
                              isExpanded: true,
                              items: categoriesWithSubcategories.keys.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedCategory = newValue;
                                  selectedSubcategory = null; // Reset subcategory when category changes
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Te rog selectează o categorie';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            // Subcategory Dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Subcategorie',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                              ),
                              value: selectedSubcategory,
                              hint: const Text('Selectează subcategoria'),
                              isExpanded: true,
                              items: selectedCategory == null
                                  ? null
                                  : categoriesWithSubcategories[selectedCategory]?.map((String subcategory) {
                                      return DropdownMenuItem<String>(
                                        value: subcategory,
                                        child: Text(
                                          subcategory,
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                              onChanged: selectedCategory == null
                                  ? null
                                  : (String? newValue) {
                                      setState(() {
                                        selectedSubcategory = newValue;
                                      });
                                    },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Te rog selectează o subcategorie';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15.0),
                      ButtonTheme(
                        minWidth: MediaQuery.of(context).size.width * 0.93,
                        height: 60,
                        child: TextButton(
                          onPressed: () async {
                            await _showWorkScheduleDialog();
                          },
                          child: Text(
                              'Setați programul de lucru (${getSelectedDaysString()} ${_formatTimeOfDay(selectedOpenTime)} - ${_formatTimeOfDay(selectedCloseTime)})'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          if (_formKey.currentState!.validate()) {
                            // Check if required fields are filled
                            if (selectedCity == null || selectedCity!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vă rugăm să selectați o locație')),
                              );
                              return;
                            }

                            if (selectedDays.every((day) => !day)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vă rugăm să selectați cel puțin o zi lucrătoare')),
                              );
                              return;
                            }

                            if (selectedOpenTime == null || selectedCloseTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vă rugăm să setați atât ora de deschidere, cât și ora de închidere')),
                              );
                              return;
                            }

                            try {
                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return const Center(child: CircularProgressIndicator());
                                },
                              );

                              String workingDays = getSelectedDaysString();
                              String openTime = _formatTimeOfDay(selectedOpenTime);
                              String closeTime = _formatTimeOfDay(selectedCloseTime);

                              // Main user data
                              Map<String, dynamic> userData = {
                                'address': selectedCity,
                                'disabled': false,
                                'workingDays': workingDays,
                                'openTime': openTime,
                                'closeTime': closeTime,
                                'createdAt': FieldValue.serverTimestamp(),
                              };

                              // Create the subcollection path
                              String subcollectionPath = '${selectedCategory}/${selectedSubcategory}';

                              // Update all collections in parallel using Future.wait
                              await Future.wait([
                                // Update main user document
                                FirebaseFirestore.instance
                                    .collection('Users')
                                    .doc(userId)
                                    .set(userData, SetOptions(merge: true)),

                                // Update BusinessAccount subcollection
                                FirebaseFirestore.instance
                                    .collection('Users')
                                    .doc(userId)
                                    .collection('BusinessAccount')
                                    .doc('detail')
                                    .set({
                                  'category': selectedSubcategory,
                                  'mainCategory': selectedCategory,
                                  'workingDays': workingDays,
                                  'openTime': openTime,
                                  'closeTime': closeTime,
                                }, SetOptions(merge: true)),

                                // Create dusers document
                                FirebaseFirestore.instance
                                    .collection('dusers')
                                    .doc(userId)
                                    .set({}),

                                // Update main category collection
                                FirebaseFirestore.instance
                                    .collection(selectedCategory!)
                                    .doc(userId)
                                    .set({
                                  'id': userId,
                                  'categoryName': selectedCategory,
                                  'subcategory': selectedSubcategory,
                                  'openTime': openTime,
                                  'closeTime': closeTime,
                                  'workingDays': workingDays,
                                  'address': selectedCity,
                                }, SetOptions(merge: true)),

                                // Add document to subcategory subcollection
                                FirebaseFirestore.instance
                                    .collection(selectedCategory!)
                                    .doc(selectedSubcategory)
                                    .collection('providers')
                                    .doc(userId)
                                    .set({
                                  'id': userId,
                                  'categoryName': selectedCategory,
                                  'subcategory': selectedSubcategory,
                                  'openTime': openTime,
                                  'closeTime': closeTime,
                                  'workingDays': workingDays,
                                  'address': selectedCity,
                                }, SetOptions(merge: true)),

                                // Update Homepage SuperUser
                                FirebaseFirestore.instance
                                    .collection('Homepage SuperUser')
                                    .doc(userId)
                                    .set({
                                  'user': userId,
                                  'expired_on': DateTime.now()
                                      .add(const Duration(days: 7))
                                      .millisecondsSinceEpoch,
                                  'plan': 'free',
                                  'notified': false,
                                  'expired': false,
                                }),

                                // Update Category SuperUser
                                FirebaseFirestore.instance
                                    .collection('Category SuperUser')
                                    .doc(userId)
                                    .set({
                                  'user': userId,
                                  'expired_on': DateTime.now()
                                      .subtract(const Duration(days: 7))
                                      .millisecondsSinceEpoch,
                                  'plan': 'free',
                                  'notified': true,
                                  'expired': true,
                                }),
                              ]);

                              // Close loading indicator
                              Navigator.pop(context);

                              // Navigate to Homepage
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const Homepage()),
                              );
                            } catch (e) {
                              // Close loading indicator
                              Navigator.pop(context);
                              
                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error creating account: ${e.toString()}')),
                              );
                              print('Error saving user data: $e');
                            }
                          }
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: 50.0,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 0, 12, 180),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Center(
                              child: Text(
                            'Creează-ți contul',
                            style: TextStyle(color: Colors.white),
                          )),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Începe cu promoția ta gratuită de 7 zile',
                          style: TextStyle(fontSize: 8))
                    ],
                  ),
                ),
              ],
            ),
          )
        ]));
  }

  Future<void> _showWorkScheduleDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Setați programul de lucru'),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9, // Adjust dialog width
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Selectați zilele lucrătoare:'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 5,
                        children: List.generate(7, (index) {
                          return FilterChip(
                            label: Text(_translateDayToRomanian(daysOfWeek[index])),
                            selected: selectedDays[index],
                            backgroundColor: Colors.white,
                            onSelected: (bool selected) {
                              setState(() {
                                selectedDays[index] = selected;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      // Modified time selection layout
                      Column(
                        children: [
                          // Opening time dropdown
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedOpenTime?.format(context) ?? 'Not set',
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: 'Ora deschiderii',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: TextStyle(color: Colors.black),
                            items: [
                              const DropdownMenuItem<String>(
                                value: 'Not set',
                                child: Text('Nesetat', style: TextStyle(color: Colors.black)),
                              ),
                              ...timeSlots.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: TextStyle(color: Colors.black)),
                                );
                              }),
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                if (newValue == 'Not set') {
                                  selectedOpenTime = null;
                                } else {
                                  final parts = newValue!.split(':');
                                  selectedOpenTime = TimeOfDay(
                                    hour: int.parse(parts[0]),
                                    minute: 0,
                                  );
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          // Closing time dropdown
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedCloseTime?.format(context) ?? 'Not set',
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: 'Ora închiderii',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: TextStyle(color: Colors.black),
                            items: [
                              const DropdownMenuItem<String>(
                                value: 'Not set',
                                child: Text('Nesetat', style: TextStyle(color: Colors.black)),
                              ),
                              ...timeSlots.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: TextStyle(color: Colors.black)),
                                );
                              }),
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                if (newValue == 'Not set') {
                                  selectedCloseTime = null;
                                } else {
                                  final parts = newValue!.split(':');
                                  selectedCloseTime = TimeOfDay(
                                    hour: int.parse(parts[0]),
                                    minute: 0,
                                  );
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Anulează'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Salvează'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    this.setState(() {});
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Not set';
    return '${time.hour.toString().padLeft(2, '0')}:00';
  }

  TimeOfDay? _parseTimeString(String timeString) {
    if (timeString == 'Not set') return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    
    int? hour = int.tryParse(parts[0]);
    if (hour == null || hour < 0 || hour > 23) return null;
    
    return TimeOfDay(hour: hour, minute: 0);
  }

  String _translateDayToRomanian(String day) {
    switch (day) {
      case 'Mon':
        return 'Lun';
      case 'Tue':
        return 'Mar';
      case 'Wed':
        return 'Mie';
      case 'Thu':
        return 'Joi';
      case 'Fri':
        return 'Vin';
      case 'Sat':
        return 'Sâm';
      case 'Sun':
        return 'Dum';
      default:
        return day;
    }
  }
}

class MySelectionItem extends StatelessWidget {
  final String title;
  final bool isForList;

  const MySelectionItem({super.key, required this.title, this.isForList = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80.0,
      child: isForList
          ? Padding(
              child: _buildItem(context),
              padding: const EdgeInsets.all(10.0),
            )
          : Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Stack(
                children: <Widget>[
                  _buildItem(context),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.arrow_drop_down),
                  )
                ],
              ),
            ),
    );
  }

  _buildItem(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      alignment: Alignment.center,
      color: Colors.white,
      child: Text(title),
    );
  }
}
