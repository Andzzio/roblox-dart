void evenNumbers(int limit) {
  for (int i = 0; i <= limit; i++) {
    if (i % 2 == 0) {
      print(i);
    }
  }
}

void oddNumbers(int limit) {
  int i = 1;
  while (i <= limit) {
    print(i);
    i += 2;
  }
}

void multiplesOf3(int limit) {
  int i = 1;
  do {
    if (i % 3 == 0) {
      print(i);
    }
    i++;
  } while (i <= limit);
}

void listTest() {
  List<int> numbers = [1, 2, 3, 4, 5];
  for (int number in numbers) {
    print(number);
  }
}

int fact({int max = 10}) {
  if (max == 0) return 1;
  return max * fact(max: max - 1);
}

void main() {
  evenNumbers(10);
  oddNumbers(10);
  multiplesOf3(10);
  listTest();

  print(fact(max: 5));
}
