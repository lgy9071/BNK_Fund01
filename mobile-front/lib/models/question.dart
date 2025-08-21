class Question {
  final String text;
  final List<String> options;
  final bool multi;

  const Question({
    required this.text,
    required this.options,
    this.multi = false,
  });
}