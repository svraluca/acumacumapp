import 'package:fl_geocoder/fl_geocoder.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:acumacum/ui/transport_category.dart';
import 'package:acumacum/utils/constants.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoriesScroller extends StatefulWidget {
  const CategoriesScroller({super.key});

  @override
  State<CategoriesScroller> createState() => _CategoriesScrollerState();
}

class _CategoriesScrollerState extends State<CategoriesScroller> {
  final ScrollController _scrollController = ScrollController();
  double _scrollPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollPercentage);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollPercentage);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollPercentage() {
    if (_scrollController.position.maxScrollExtent > 0) {
      setState(() {
        _scrollPercentage = _scrollController.offset / _scrollController.position.maxScrollExtent;
      });
    }
  }

  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final categories = [
      "Agricultura",
      "Ajutor Personal",
      "Animale",
      "Auto",
      "Artistice",
      "Saloane si Frizerii",
      "Constructii",
      "Curatenie",
      "Consultanta",
      "Electrice",
      "Educatie",
      "Evenimente",
      "Finante si Asigurari",
      "Fitness",
      "Freelancing",
      "Amenajari Exterioare",
      "Instalatii",
      "Sanatate si Medical",
      "Legal si Consultanta",
      "Logistica",
      "Turism",
      "Marketing",
      "Familie",
      "Media",
    ];

    // Split categories into pairs
    final List<List<String>> pairedCategories = [];
    for (var i = 0; i < categories.length; i += 2) {
      if (i + 1 < categories.length) {
        pairedCategories.add([categories[i], categories[i + 1]]);
      } else {
        pairedCategories.add([categories[i]]); // For the last odd item
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Image.asset(
              'assets/images/slide2.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: pairedCategories
                      .map((pair) => _buildCategoryPair(context, pair))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 3,
                      width: MediaQuery.of(context).size.width * 0.3,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scrollNotification) {
                          if (scrollNotification is ScrollUpdateNotification) {
                            setState(() {
                              _scrollPercentage = _scrollController.offset / 
                                  (_scrollController.position.maxScrollExtent);
                            });
                          }
                          return true;
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Positioned(
                                  left: constraints.maxWidth * _scrollPercentage.clamp(0.0, 0.7),
                                  child: Container(
                                    height: 3,
                                    width: constraints.maxWidth * 0.3,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildSlideshow(),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Image.asset(
              'assets/images/OFF.png',
              width: MediaQuery.of(context).size.width * 1,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlideshow() {
    final List<String> slideshowImages = [
      'assets/images/slide1.png',
      'assets/images/slide3.png',
      'assets/images/slide5.png',
      
      'assets/images/slide4.png',
    ];

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 200,
            autoPlay: false,
            enlargeCenterPage: true,
            enlargeFactor: 0.3,
            viewportFraction: 0.95,
            enableInfiniteScroll: false,
            scrollPhysics: const BouncingScrollPhysics(),
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
          items: slideshowImages.map((imagePath) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: slideshowImages.asMap().entries.map((entry) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _current == entry.key
                    ? Colors.black.withOpacity(0.9)
                    : Colors.black.withOpacity(0.4),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryPair(BuildContext context, List<String> categoryPair) {
    return SizedBox(
      width: 95,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            _buildSingleCategory(context, categoryPair[0]),
            if (categoryPair.length > 1) ...[
              const SizedBox(height: 4),
              _buildSingleCategory(context, categoryPair[1]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSingleCategory(BuildContext context, String category) {
    return GestureDetector(
      onTap: () async {
        List<String> location = await getLocation();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransportScreen(
              category,
              location,
              "",
            ),
          ),
        );
      },
      child: SizedBox(
        height: 130,
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Color(0xFFF5F5F5),  // Light grey in center
                        Color(0xFFEEEEEE),  // Slightly darker grey at edges
                      ],
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: category == "Agricultura" 
                          ? Image.asset(
                              'assets/images/farmmachine.png',
                              fit: BoxFit.cover,
                            )
                          : category == "Animale"
                              ? Image.asset(
                                  'assets/images/animal-care.png',
                                  fit: BoxFit.cover,
                                )
                              : category == "Auto"
                                  ? Image.asset(
                                      'assets/images/maintenance.png',
                                      fit: BoxFit.cover,
                                    )
                                  : category == "Artistice"
                                      ? Image.asset(
                                          'assets/images/paint-palette.png',
                                          fit: BoxFit.cover,
                                        )
                                      : category == "Saloane si Frizerii"
                                          ? Image.asset(
                                              'assets/images/hair-dye-brush.png',
                                              fit: BoxFit.cover,
                                            )
                                          : category == "Constructii"
                                              ? Image.asset(
                                                  'assets/images/work-in-progress.png',
                                                  fit: BoxFit.cover,
                                                )
                                              : category == "Curatenie"
                                                  ? Image.asset(
                                                      'assets/images/window-cleaning.png',
                                                      fit: BoxFit.cover,
                                                    )
                                                  : category == "Consultanta"
                                                      ? Image.asset(
                                                          'assets/images/consultant-service.png',
                                                          fit: BoxFit.cover,
                                                        )
                                                      : category == "Electrice"
                                                          ? Image.asset(
                                                              'assets/images/electric-meter.png',
                                                              fit: BoxFit.cover,
                                                            )
                                                          : category == "Educatie"
                                                              ? Image.asset(
                                                                  'assets/images/graduation-cap.png',
                                                                  fit: BoxFit.cover,
                                                                )
                                                              : category == "Evenimente"
                                                                  ? Image.asset(
                                                                      'assets/images/event.png',
                                                                      fit: BoxFit.cover,
                                                                    )
                                                                  : category == "Energie si Mediu"
                                                                      ? Image.asset(
                                                                          'assets/images/save.png',
                                                                          fit: BoxFit.cover,
                                                                        )
                                                                      : category == "Finante si Asigurari"
                                                                          ? Image.asset(
                                                                              'assets/images/business.png',
                                                                              fit: BoxFit.cover,
                                                                            )
                                                                          : category == "Fitness"
                                                                              ? Image.asset(
                                                                                  'assets/images/barbell.png',
                                                                                  fit: BoxFit.cover,
                                                                                )
                                                                              : category == "Freelancing"
                                                                                  ? Image.asset(
                                                                                      'assets/images/computer-worker.png',
                                                                                      fit: BoxFit.cover,
                                                                                    )
                                                                                  : category == "Amenajari Exterioare"
                                                                                      ? Image.asset(
                                                                                          'assets/images/planting.png',
                                                                                          fit: BoxFit.cover,
                                                                                        )
                                                                                      : category == "Instalatii"
                                                                                          ? Image.asset(
                                                                                              'assets/images/account-maintenance.png',
                                                                                              fit: BoxFit.cover,
                                                                                            )
                                                                                          : category == "Sanatate si Medical"
                                                                                              ? Image.asset(
                                                                                                  'assets/images/doctor.png',
                                                                                                  fit: BoxFit.cover,
                                                                                                )
                                                                                              : category == "Legal si Consultanta"
                                                                                                  ? Image.asset(
                                                                                                      'assets/images/law.png',
                                                                                                      fit: BoxFit.cover,
                                                                                                    )
                                                                                                  : category == "Logistica"
                                                                                                      ? Image.asset(
                                                                                                          'assets/images/trolley.png',
                                                                                                          fit: BoxFit.cover,
                                                                                                        )
                                                                                                      : category == "Turism"
                                                                                                          ? Image.asset(
                                                                                                              'assets/images/island.png',
                                                                                                              fit: BoxFit.cover,
                                                                                                            )
                                                                                                          : category == "Marketing"
                                                                                                              ? Image.asset(
                                                                                                                  'assets/images/social-media.png',
                                                                                                                  fit: BoxFit.cover,
                                                                                                                )
                                                                                                              : category == "Familie"
                                                                                                                  ? Image.asset(
                                                                                                                      'assets/images/dad.png',
                                                                                                                      fit: BoxFit.cover,
                                                                                                                    )
                                                                                                                  : category == "Media"
                                                                                                                      ? Image.asset(
                                                                                                                          'assets/images/photography.png',
                                                                                                                          fit: BoxFit.cover,
                                                                                                                        )
                                                                                                                      : category == "Ajutor Personal"
                                                                                                                          ? Image.asset(
                                                                                                                              'assets/images/tailor.png',
                                                                                                                              fit: BoxFit.cover,
                                                                                                                            )
                                                                                                                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                SizedBox(
                  height: 32,
                  child: Text(
                    category,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.2,
                      letterSpacing: -0.3,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
            if (category == "Agricultura" ||
                category == "Animale" ||
                category == "Constructii" ||
                category == "Auto" ||
                category == "Logistica" ||
                category == "Media" ||
                category == "Familie")
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> getLocation() async {
    List<String> locationList = [];
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final coordinates = Location(position.latitude, position.longitude);

      final addresses = await FlGeocoder(Constants.googlePlaceKey)
          .findAddressesFromLocationCoordinates(location: coordinates);
      locationList.add(addresses.first.country!.longName);
      locationList.add(addresses.first.country!.shortName!);
      print('in get location ');
      print("${locationList[0]}   ${locationList[1]}");
      return locationList;
    } catch (e) {
      if (e is PermissionDeniedException) {
        print(e);
      }
      return locationList;
    }
  }
}
