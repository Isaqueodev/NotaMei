import 'package:flutter/material.dart';

import 'app/startup_screen.dart';
import 'data/entry_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(StartupScreen(repository: EntryRepository()));
}