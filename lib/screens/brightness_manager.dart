class BrightnessManager {
  BrightnessManager._privateConstructor();
  static final BrightnessManager _instance = BrightnessManager._privateConstructor();
  static BrightnessManager get instance => _instance;

  double _brightness = 0.0;
  List<void Function(double)> _listeners = [];

  double get brightness => _brightness;

  void setBrightness(double value) {
    _brightness = value;
    for (var listener in _listeners) {
      listener(_brightness);
    }
  }

  void addListener(void Function(double) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(double) listener) {
    _listeners.remove(listener);
  }
}
