import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jobseeker/features/models/question.dart';
import 'package:jobseeker/features/models/reply.dart';
import 'package:jobseeker/features/repositories/forum_repository.dart';

class ForumProvider with ChangeNotifier {
  final ForumRepository _repository;

  List<Question> _questions = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Question>>? _questionsSubscription;

  ForumProvider(this._repository) {
    loadQuestions();
  }

  // Getters
  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Listen to the stream of questions
  void loadQuestions() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _questionsSubscription?.cancel();
    _questionsSubscription = _repository.getQuestions().listen(
      (questions) {
        _questions = questions;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  // Create a new question
  Future<void> createQuestion(Question question) async {
    try {
      _setLoading(true);
      await _repository.createQuestion(question);
      _setLoading(false);
    } catch (e) {
      _handleError(e.toString());
      rethrow;
    }
  }

  // Add a reply to a question
  Future<void> addReply(String questionId, Reply reply) async {
    try {
      await _repository.addReply(questionId, reply);
    } catch (e) {
      _handleError(e.toString());
      rethrow;
    }
  }

  // Upvote a question
  Future<void> upvoteQuestion(String questionId) async {
    try {
      await _repository.upvoteQuestion(questionId);
    } catch (e) {
      _handleError(e.toString());
      rethrow;
    }
  }

  // Helper methods to update state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _handleError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _questionsSubscription?.cancel();
    super.dispose();
  }
}
