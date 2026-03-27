class SequenceResult<T> {
  final String sequenceName;
  final List<T> data;
  final DateTime generatedAt;

  SequenceResult(this.sequenceName, this.data) : generatedAt = DateTime.now();

  void printSummary() {
    print(
      "`$sequenceName` Summary:\n"
      "Generated: $generatedAt\n"
      "Data: [${data.join(', ')}]\n"
      "Length: ${data.length} items.\n"
      "___________________________________",
    );
  }
}

typedef FibonacciGenerator = int Function();

FibonacciGenerator _createFibGenerator(int max) {
  int a = 0;
  int b = 1;

  int next() {
    final int nextValue = a + b;
    a = b;
    b = nextValue;
    return a;
  }

  return next;
}

void simulateFibonacci(int count) {
  print("=== FIBONACCI GENERATOR WITH COMPLEX STATE ===\n");

  final FibonacciGenerator gen = _createFibGenerator(count);
  final List<int> sequence = [];

  int i = 0;
  while (true) {
    if (i >= count) {
      break;
    }

    final int result = gen();

    if (result % 2 != 0) {
      i++;
      continue;
    }

    sequence.add(result);
    i++;
  }

  final SequenceResult<int> finalResult = SequenceResult<int>(
    "Even Fibonacci",
    sequence,
  );

  finalResult.printSummary();
}

void main() {
  simulateFibonacci(10);
}
