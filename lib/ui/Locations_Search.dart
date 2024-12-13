import 'package:flutter/material.dart';

class LocationSearch extends StatefulWidget {
  const LocationSearch({Key? key}) : super(key: key);

  @override
  State<LocationSearch> createState() => _LocationSearchState();
}

class _LocationSearchState extends State<LocationSearch> {
  String? selectedCounty;
  String? selectedCity;
  
  final Map<String, List<String>> romanianLocations = {
    'Alba': ['Alba Iulia', 'Sebeș', 'Aiud', 'Cugir'],
    'Arad': ['Arad', 'Ineu', 'Lipova', 'Pecica'],
    'Argeș': ['Pitești', 'Câmpulung', 'Curtea de Argeș', 'Mioveni'],
    'Bacău': ['Bacău', 'Onești', 'Moinești', 'Comănești'],
    'Bihor': ['Oradea', 'Salonta', 'Marghita', 'Beiuș'],
    'Bistrița-Năsăud': ['Bistrița', 'Năsăud', 'Beclean', 'Sângeorz-Băi'],
    'Botoșani': ['Botoșani', 'Dorohoi', 'Darabani', 'Săveni'],
    'Brașov': ['Brașov', 'Făgăraș', 'Săcele', 'Codlea'],
    'Brăila': ['Brăila', 'Ianca', 'Însurăței', 'Făurei'],
    'București': ['Sector 1', 'Sector 2', 'Sector 3', 'Sector 4', 'Sector 5', 'Sector 6'],
    'Buzău': ['Buzău', 'Râmnicu Sărat', 'Nehoiu', 'Pătârlagele'],
    'Caraș-Severin': ['Reșița', 'Caransebeș', 'Bocșa', 'Oravița'],
    'Călărași': ['Călărași', 'Oltenița', 'Budești', 'Fundulea'],
    'Cluj': ['Cluj-Napoca', 'Turda', 'Dej', 'Câmpia Turzii'],
    'Constanța': ['Constanța', 'Mangalia', 'Medgidia', 'Năvodari'],
    'Covasna': ['Sfântu Gheorghe', 'Târgu Secuiesc', 'Covasna', 'Baraolt'],
    'Dâmbovița': ['Târgoviște', 'Moreni', 'Pucioasa', 'Găești'],
    'Dolj': ['Craiova', 'Băilești', 'Calafat', 'Filiași'],
    'Galați': ['Galați', 'Tecuci', 'Târgu Bujor', 'Berești'],
    'Giurgiu': ['Giurgiu', 'Bolintin-Vale', 'Mihăilești'],
    'Gorj': ['Târgu Jiu', 'Motru', 'Rovinari', 'Bumbești-Jiu'],
    'Harghita': ['Miercurea Ciuc', 'Odorheiu Secuiesc', 'Gheorgheni', 'Toplița'],
    'Hunedoara': ['Deva', 'Hunedoara', 'Petroșani', 'Vulcan'],
    'Ialomița': ['Slobozia', 'Fetești', 'Urziceni', 'Țăndărei'],
    'Iași': ['Iași', 'Pașcani', 'Hârlău', 'Târgu Frumos'],
    'Ilfov': ['Buftea', 'Voluntari', 'Pantelimon', 'Bragadiru'],
    'Maramureș': ['Baia Mare', 'Sighetu Marmației', 'Borșa', 'Vișeu de Sus'],
    'Mehedinți': ['Drobeta-Turnu Severin', 'Orșova', 'Strehaia', 'Vânju Mare'],
    'Mureș': ['Târgu Mureș', 'Reghin', 'Sighișoara', 'Târnăveni'],
    'Neamț': ['Piatra Neamț', 'Roman', 'Târgu Neamț', 'Bicaz'],
    'Olt': ['Slatina', 'Caracal', 'Balș', 'Corabia'],
    'Prahova': ['Ploiești', 'Câmpina', 'Băicoi', 'Mizil'],
    'Satu Mare': ['Satu Mare', 'Carei', 'Negrești-Oaș', 'Tășnad'],
    'Sălaj': ['Zalău', 'Șimleu Silvaniei', 'Jibou', 'Cehu Silvaniei'],
    'Sibiu': ['Sibiu', 'Mediaș', 'Cisnădie', 'Avrig'],
    'Suceava': ['Suceava', 'Fălticeni', 'Rădăuți', 'Câmpulung Moldovenesc'],
    'Teleorman': ['Alexandria', 'Roșiorii de Vede', 'Turnu Măgurele', 'Zimnicea'],
    'Timiș': ['Timișoara', 'Lugoj', 'Sânnicolau Mare', 'Jimbolia'],
    'Tulcea': ['Tulcea', 'Măcin', 'Babadag', 'Isaccea'],
    'Vaslui': ['Vaslui', 'Bârlad', 'Huși', 'Negrești'],
    'Vâlcea': ['Râmnicu Vâlcea', 'Drăgășani', 'Băbeni', 'Brezoi'],
    'Vrancea': ['Focșani', 'Adjud', 'Mărășești', 'Panciu'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Select Location',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedCounty == null || selectedCity == null) ...[
              Text(
                'County',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              // County Selection
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  value: selectedCounty,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  style: TextStyle(color: Colors.black),
                  hint: Text('Select County', style: TextStyle(color: Colors.grey)),
                  items: romanianLocations.keys.map((String county) {
                    return DropdownMenuItem<String>(
                      value: county,
                      child: Text(county),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCounty = newValue;
                      selectedCity = null; // Reset city when county changes
                    });
                  },
                ),
              ),
              SizedBox(height: 24),
              Text(
                'City',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              // City Selection
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  value: selectedCity,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  style: TextStyle(color: Colors.black),
                  hint: Text('Select City', style: TextStyle(color: Colors.grey)),
                  items: selectedCounty != null
                      ? romanianLocations[selectedCounty]?.map((String city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(city),
                          );
                        }).toList()
                      : [],
                  onChanged: selectedCounty == null
                      ? null
                      : (String? newValue) {
                          setState(() {
                            selectedCity = newValue;
                          });
                        },
                ),
              ),
            ] else ...[
              // Display selected location
              Text(
                'Selected Location:',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '$selectedCounty, $selectedCity',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            SizedBox(height: 32),
            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedCounty != null && selectedCity != null
                    ? () {
                        Navigator.pop(context, '$selectedCounty, $selectedCity');
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFC8102E),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Confirma locatia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
}
