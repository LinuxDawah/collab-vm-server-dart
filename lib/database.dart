import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class Database
{
  late sqlite3.Database database;
  Database(String filename){
    open.overrideFor(OperatingSystem.windows, _openOnWindows);
    database = sqlite3.sqlite3.open(filename);
    try {
      // Try to query the Config.
      final sqlite3.ResultSet config = database.select("SELECT * FROM Config;");
      print(config);
    }catch(e) {
      // If the query errors, initalize the database
      initalizeDB();
    }
  }
  DynamicLibrary _openOnWindows() {
    final scriptDir = File(Platform.script.toFilePath()).parent;
    final libraryNextToScript = File('${scriptDir.path}/sqlite3.dll');
    return DynamicLibrary.open(libraryNextToScript.path);
  }

initalizeDB() {
	// Initalize database	
	// Create main config table
  database.execute('''
	CREATE TABLE "Config" (
  "ID" INTEGER NOT NULL PRIMARY KEY,
  "MasterPassword" TEXT NOT NULL,
  "MaxConnections" INTEGER NOT NULL,
  "ChatRateCount" INTEGER NOT NULL,
  "ChatRateTime" INTEGER NOT NULL,
  "ChatMuteTime" INTEGER NOT NULL,
  "ChatMsgHistory" INTEGER NOT NULL)
	''');

	// Create VM Settings template
	database.execute('''
	CREATE TABLE "VMSettings" (
  "Name" TEXT NOT NULL PRIMARY KEY,
  "AutoStart" INTEGER NOT NULL,
  "DisplayName" TEXT NOT NULL,
  "TurnsEnabled" INTEGER NOT NULL,
  "TurnTime" INTEGER NOT NULL,
  "VotesEnabled" INTEGER NOT NULL,
  "VoteTime" INTEGER NOT NULL,
  "VoteCooldownTime" INTEGER NOT NULL,
  "VNCAddress" TEXT NOT NULL,
  "VNCPort" INTEGER NOT NULL,
  "QMPSocketType" INTEGER NOT NULL,
  "QMPAddress" TEXT NOT NULL,
  "QMPPort" INTEGER NOT NULL,
  "QEMUCmd" TEXT NOT NULL)
	''');
	
   print("A new database has been created");
}
}