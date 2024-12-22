import '../models/action_model.dart';

class ActionService {
  static final ActionService _instance = ActionService._internal();
  factory ActionService() => _instance;
  ActionService._internal();

  final List<ZoneAction> _actions = [];

  List<ZoneAction> get actions => _actions;

  void addAction(ZoneAction action) {
    _actions.add(action);
  }
}
