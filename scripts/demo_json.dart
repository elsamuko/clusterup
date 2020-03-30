#!/usr/bin/env dart
import 'dart:convert';

int main() {
  List<String> actionNames = ["Hase"];
  print(jsonEncode(actionNames));

  actionNames = jsonDecode("[\"df\", \"ls\"]").cast<String>();
  print(actionNames);

  actionNames = jsonDecode("[]").cast<String>();
  print(actionNames);

  return 0;
}
