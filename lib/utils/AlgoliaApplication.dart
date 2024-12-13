import 'package:algolia/algolia.dart';

class AlgoliaApplication{
  static const Algolia algolia = Algolia.init(
    applicationId: 'G5GU355VU9', //ApplicationID
    apiKey: '4b20131d24e9a03ce83ad473e8232d3d', //search-only api key in flutter code
  );
}