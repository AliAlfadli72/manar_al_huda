import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/question.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String avatar,
  }) async {
    final UserCredential creds = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    if (creds.user != null) {
      await creds.user!.updateDisplayName(name);
      
      // Create user profile in Firestore
      await _firestore.collection('users').doc(creds.user!.uid).set({
        'uid': creds.user!.uid,
        'name': name,
        'email': email.trim(),
        'avatar': avatar,
        'points': 0,
        'wins': 0,
        'losses': 0,
        'streak': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return creds;
  }

  // Login
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Delete Account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      final uid = user.uid;
      try {
        await _firestore.collection('users').doc(uid).delete();
      } catch (_) {}
      await user.delete();
    }
  }


  // Stream user profile
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // Get user profile once
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // Increment points from offline/single-player games
  Future<void> addPoints(int points) async {
    final user = currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'points': FieldValue.increment(points),
    });
  }

  // Sync local offline stats to Firestore
  Future<void> syncLocalStats({
    required int points,
    required int streak,
  }) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'points': points,
        'streak': streak,
      });
    } catch (e) {
      // ignore
    }
  }

  // Retrieve 5 random questions for seeding the duel room
  Future<List<Question>> _get5RandomQuestions(String categoryId) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/questions_fallback.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      if (data['questions'] is List) {
        final List<dynamic> allQuestions = data['questions'];
        final List<Question> filtered = allQuestions
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .where((q) => q.category == categoryId)
            .toList();
        
        final random = Random();
        final List<Question> shuffled = List<Question>.from(filtered)..shuffle(random);
        return shuffled.take(5).toList();
      }
    } catch (e) {
      // fallback below
    }

    return [
      Question(
        id: 'fallback_quran_1',
        category: categoryId,
        question: 'ما هي أعظم آية في القرآن الكريم؟',
        options: ['آية الكرسي', 'آية الدين', 'آخر آية في سورة البقرة'],
        correctAnswerIndex: 0,
        explanation: 'آية الكرسي (البقرة: 255) هي أعظم آية في كتاب الله لما تشمل عليه من معاني التوحيد والصفات العلية لله سبحانه وتعالى.',
        verseOrHadithText: '«اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...»',
      ),
      Question(
        id: 'fallback_quran_2',
        category: categoryId,
        question: 'ما هي السورة التي تشادل عن صاحبها في القبر حتى يغفر له؟',
        options: ['سورة الملك', 'سورة السجدة', 'سورة يس'],
        correctAnswerIndex: 0,
        explanation: 'ورد في الحديث الشريف أن سورة تبارك (الملك) هي ثلاثون آية شفعت لرجل حتى غفر له.',
        verseOrHadithText: '«تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ»',
      )
    ];
  }

  // Create a Duel Room
  Future<String> createDuelRoom(String categoryId) async {
    final user = currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول لإنشاء تحدي');

    final profile = await getUserProfile(user.uid);
    final String name = profile.data()?['name'] ?? user.displayName ?? 'لاعب 1';
    final String avatar = profile.data()?['avatar'] ?? 'avatar1';

    // Generate a 6-digit room code
    final random = Random();
    final String roomCode = (random.nextInt(900000) + 100000).toString(); // '100000' to '999999'

    final List<Question> questions = await _get5RandomQuestions(categoryId);
    final List<Map<String, dynamic>> questionsJson = questions.map((q) => q.toJson()).toList();

    await _firestore.collection('duels').doc(roomCode).set({
      'roomId': roomCode,
      'categoryId': categoryId,
      'creatorUid': user.uid,
      'creatorName': name,
      'creatorAvatar': avatar,
      'joinerUid': null,
      'joinerName': null,
      'joinerAvatar': null,
      'status': 'waiting', // waiting, playing, finished
      'questions': questionsJson,
      'currentQuestionIndex': 0,
      'scores': {
        user.uid: 0,
      },
      'answers': {
        user.uid: {},
      },
      'creatorActive': true,
      'joinerActive': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return roomCode;
  }

  // Join a Duel Room
  Future<void> joinDuelRoom(String roomCode) async {
    final user = currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول للانضمام للتحدي');

    final docRef = _firestore.collection('duels').doc(roomCode);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('رمز الغرفة غير صحيح أو انتهت صلاحيتها');
    }

    final data = doc.data()!;
    if (data['joinerUid'] != null) {
      throw Exception('هذا التحدي ممتلئ بالفعل');
    }

    if (data['creatorUid'] == user.uid) {
      throw Exception('لا يمكنك الانضمام لتحدي قمت بإنشائه بنفسك');
    }

    final profile = await getUserProfile(user.uid);
    final String name = profile.data()?['name'] ?? user.displayName ?? 'لاعب 2';
    final String avatar = profile.data()?['avatar'] ?? 'avatar1';

    await docRef.update({
      'joinerUid': user.uid,
      'joinerName': name,
      'joinerAvatar': avatar,
      'status': 'playing',
      'joinerActive': true,
      'scores.${user.uid}': 0,
      'answers.${user.uid}': {},
    });
  }

  // Stream Duel Room Changes
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDuelRoom(String roomId) {
    return _firestore.collection('duels').doc(roomId).snapshots();
  }

  // Submit Answer in Duel Room
  Future<void> submitAnswer({
    required String roomId,
    required String questionId,
    required int selectedIndex,
    required bool isCorrect,
    required int timeLeft,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('duels').doc(roomId);

    // Increment score if correct
    final int points = isCorrect ? (10 + timeLeft) : 0;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final Map<String, dynamic> answers = Map<String, dynamic>.from(data['answers'] ?? {});
      final Map<String, dynamic> playerAnswers = Map<String, dynamic>.from(answers[user.uid] ?? {});
      final Map<String, dynamic> scores = Map<String, dynamic>.from(data['scores'] ?? {});

      // Save answer
      playerAnswers[questionId] = selectedIndex;
      answers[user.uid] = playerAnswers;

      // Update score
      final int currentScore = scores[user.uid] ?? 0;
      scores[user.uid] = currentScore + points;

      transaction.update(docRef, {
        'answers': answers,
        'scores': scores,
      });
    });
  }

  // Advance Duel Room Question Index
  Future<void> advanceDuelQuestion(String roomId, int nextIndex) async {
    await _firestore.collection('duels').doc(roomId).update({
      'currentQuestionIndex': nextIndex,
    });
  }

  // End the Duel and save stats
  Future<void> endDuel({
    required String roomId,
    required String winnerUid,
    required String creatorUid,
    required String joinerUid,
    required int creatorScore,
    required int joinerScore,
  }) async {
    await _firestore.collection('duels').doc(roomId).update({
      'status': 'finished',
      'winnerUid': winnerUid,
    });

    final String userUid = currentUser?.uid ?? '';
    // Only let one participant run the stats updates to avoid double increments
    if (userUid != creatorUid) return;

    // Update Creator profile stats
    final creatorRef = _firestore.collection('users').doc(creatorUid);
    if (winnerUid == 'draw') {
      await creatorRef.update({
        'points': FieldValue.increment(creatorScore + 5), // small draw bonus
      });
    } else if (winnerUid == creatorUid) {
      await creatorRef.update({
        'points': FieldValue.increment(creatorScore + 15), // win bonus
        'wins': FieldValue.increment(1),
      });
    } else {
      await creatorRef.update({
        'points': FieldValue.increment(creatorScore),
        'losses': FieldValue.increment(1),
      });
    }

    // Update Joiner profile stats
    final joinerRef = _firestore.collection('users').doc(joinerUid);
    if (winnerUid == 'draw') {
      await joinerRef.update({
        'points': FieldValue.increment(joinerScore + 5),
      });
    } else if (winnerUid == joinerUid) {
      await joinerRef.update({
        'points': FieldValue.increment(joinerScore + 15),
        'wins': FieldValue.increment(1),
      });
    } else {
      await joinerRef.update({
        'points': FieldValue.increment(joinerScore),
        'losses': FieldValue.increment(1),
      });
    }
  }
}
