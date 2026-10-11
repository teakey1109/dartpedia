import 'package:wikipedia/wikipedia.dart' as wikipedia;

void main(List<String> arguments) {
  wikipedia.getRandomSummary().then((summary) {
    print('Hello world: $summary!');
  });
}
