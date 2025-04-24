import 'package:cloud_firestore/cloud_firestore.dart';

class ApiUsageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> canMakeRequest(String userId) async {
    final docRef = _firestore.collection('api_usage').doc(userId);

    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(docRef);
        final now = DateTime.now();

        final data =
            doc.exists
                ? doc.data()!
                : {
                  'minuteCount': 0,
                  'dailyCount': 0,
                  'lastReset': Timestamp.fromDate(now),
                  'lastRequest': Timestamp.fromDate(now),
                };

        final lastRequest = (data['lastRequest'] as Timestamp).toDate();
        if (now.difference(lastRequest).inMinutes < 1 &&
            data['minuteCount'] >= 6) {
          return false;
        }

        if (data['dailyCount'] >= 60) {
          return false;
        }

        transaction.set(docRef, {
          'minuteCount':
              now.difference(lastRequest).inMinutes < 1
                  ? data['minuteCount'] + 1
                  : 1,
          'dailyCount': data['dailyCount'] + 1,
          'lastRequest': Timestamp.fromDate(now),
        });

        return true;
      });
    } catch (e) {
      print("Ocorreu um erro");
      return false;
    }
  }
}
