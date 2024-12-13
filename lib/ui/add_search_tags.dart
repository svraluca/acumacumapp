import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddSearchTags extends StatefulWidget {
  const AddSearchTags({super.key, required this.id});

  final String id;

  @override
  _AddSearchTagsState createState() => _AddSearchTagsState();
}

class _AddSearchTagsState extends State<AddSearchTags> {
  final TextEditingController searchText = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adauga cuvinte cheie'),
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            const Text(
                'Adauga cuvinte cheie cu serviciile pe care le oferi pentru a fi usor de gasit de clienti.\n\nex: constructii,design,constructor,casa,finisaje,renovari'),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: searchText,
              maxLines: null,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: 'Adauga cuvinte cheie'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              onPressed: () async {
                if (searchText.text != '') {
                  await FirebaseFirestore.instance.collection('Users').doc(widget.id).update({
                    'searchText': searchText.text,
                  });
                }
              },
              child: const Text(
                'Save Tags',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('Users').doc(widget.id).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return (snapshot.data!.data() as Map)['searchText'] == null
                      ? Container()
                      : Container(
                          color: Colors.grey[300],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ListTile(
                                title: Text((snapshot.data!.data() as Map)['searchText']),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                onPressed: () {
                                  FirebaseFirestore.instance.collection('Users').doc(widget.id).update({
                                    'searchText': null,
                                  });
                                },
                                child: const Text(
                                  'Delete the tags',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                })
          ],
        ),
      ),
    );
  }
}
