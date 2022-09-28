import 'dart:developer';
import 'package:mongo_dart/mongo_dart.dart';

const MONGO_URL = "mongodb+srv://test1:test1@cluster0.w71jyop.mongodb.net/testdb1?retryWrites=true&w=majority";
const COLLECTION_NAME = "users";

class MongoDB{
  static connect() async{
    var db = await Db.create(MONGO_URL);
    await db.open();
    // inspect(db);
    var collection = db.collection(COLLECTION_NAME);
    print(await collection.find().toList());
    await collection.insertMany([
      {'login': 'jdoe', 'name': 'John Doe', 'email': 'john@doe.com'},
      {'login': 'lsmith', 'name': 'Lucy Smith', 'email': 'lucy@smith.com'}
    ]);
  }
}