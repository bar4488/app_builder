extension Let<T> on T {
  R? let<R>(R Function(T it) func) => this != null ? func(this!) : null;
}
