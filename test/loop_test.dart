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

void main() {
  evenNumbers(10);
  oddNumbers(10);
}
