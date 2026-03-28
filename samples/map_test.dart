void main() {
  Map<String, dynamic> map = {
    "name": "Andre",
    "age": 19,
    "isStudent": true,
    "courses": ["Physics 1", "Data Structures", "Math Discrete"],
  };

  print(map["name"]);
  print(map["age"]);
  print(map["isStudent"]);

  for (String course in map["courses"]) {
    print(course);
  }
}
