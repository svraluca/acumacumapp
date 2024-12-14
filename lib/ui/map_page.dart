// import 'package:flutter/material.dart';

// class MapPage extends StatefulWidget {
//   const MapPage({super.key, this.loc, this.lat, this.long});

//   final loc;
//   final lat;
//   final long;
//   static const CameraPosition _kGooglePlex = CameraPosition(
//     target: LatLng(-1.9398655999999999, 30.1006848),
//     zoom: 15.4746,
//   );

//   static const CameraPosition _kLake = CameraPosition(
//       bearing: 192.8334901395799,
//       target: LatLng(-1.9398655999999999, 30.1006848),
//       tilt: 59.440717697143555,
//       zoom: 19.151926040649414);

//   @override
//   _MapPageState createState() => _MapPageState();
// }

// class _MapPageState extends State<MapPage> {
//   @override
//   Widget build(BuildContext context) {
//     Set<Marker> makers = {
//       Marker(
//         onTap: () {
//           print('Tapped');
//         },
//         draggable: false,
//         infoWindow: const InfoWindow(
//           title: 'My Location',
//         ),
//         markerId: const MarkerId('Marker'),
//         position: LatLng(widget.lat, widget.long),
//         visible: true,
//         icon: BitmapDescriptor.defaultMarker,
//       ),
//     };
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("My Location"),
//       ),
//       body: Container(
//         child: GoogleMap(
//           onMapCreated: (GoogleMapController controller) {
//             setState(() {
//               makers.add(
//                 Marker(
//                   onTap: () {
//                     print('Tapped');
//                   },
//                   draggable: false,
//                   infoWindow: const InfoWindow(
//                     title: 'My Location',
//                   ),
//                   markerId: const MarkerId('Marker'),
//                   position: LatLng(widget.lat, widget.long),
//                   visible: true,
//                   icon: BitmapDescriptor.defaultMarker,
//                 ),
//               );
//             });
//           },
//           markers: makers,
//           mapType: MapType.terrain,
//           initialCameraPosition: CameraPosition(
//             target: LatLng(widget.lat, widget.long),
//             zoom: 15.4746,
//           ),
//         ),
//       ),
//     );
//   }
// }
