use UnitTest;
use TemplateString;
use IO;

config const show = false;
proc log(msg...) {
  if show {
    writeln((...msg));
  }
}

proc testSimple(test: borrowed Test) throws {

  proc doTest(template: string,
              expected: string,
              vars,
              prefix: string,
              suffix: string,
              shouldPassPrefix: bool) throws {
    log("Testing template: '%s' with variables %? and variable wrapper ('%s', '%s')".format(template, vars, prefix, suffix));
    try {
      var t: templateString;
      if shouldPassPrefix then
        t = new templateString(template, (prefix, suffix));
      else
        t = new templateString(template);
      var o = t.fill(vars);
      test.assertEqual(o, expected);
    } catch e: TemplateStringError {
      // TODO: it would be nice to just pass the error to assert
      // TODO: it would be nice to have `test.fail("message", e)` instead
      // of assertTrue(false, "message")
      log("Caught TemplateStringError: ", e.message());
      test.assertTrue(false/*, "TemplateStringError: " + e.message()*/);
    } catch e: UnitTest.TestError.AssertionError {
      throw e;
    } catch e {
      test.assertTrue(false/*, "Unexpected error: " + e.message()*/);
    }
  }

  for (prefix, suffix, shouldPassPrefix) in [
      ("{{", "}}", false),
      ("{{", "}}", true),
      ("{", "}", true),
      ("@", "", true),
    ] {
    doTest("Hello %sname%s!".format(prefix, suffix),
            "Hello world!",
            ["name" => "world"],
            prefix, suffix, shouldPassPrefix);
    doTest("Hello %sname%s! Your name is %sname%s.".format(prefix, suffix, prefix, suffix),
            "Hello world! Your name is world.",
            ["name" => "world"],
            prefix, suffix, shouldPassPrefix);
    doTest("Hello %sname%s".format(prefix, suffix),
            "Hello world",
            ["name" => "world"],
            prefix, suffix, shouldPassPrefix);
    doTest("%sname%s!".format(prefix, suffix),
            "world!",
            ["name" => "world"],
            prefix, suffix, shouldPassPrefix);
    doTest("%sname%s".format(prefix, suffix),
            "world",
            ["name" => "world"],
            prefix, suffix, shouldPassPrefix);
    if !(prefix == "{" && suffix == "}") then
      doTest("%smyVar1%s or perhaps %smyVar2%s, but not {myVar3}".format(prefix, suffix, prefix, suffix),
              "value1 or perhaps value2, but not {myVar3}",
              ["myVar1" => "value1", "myVar2" => "value2"],
              prefix, suffix, shouldPassPrefix);
  }
}

proc testErrors(test: borrowed Test) throws {
  {
    var t = new templateString("Hello {{name");
    try {
      t.fill(["name" => "world"]);
      test.assertTrue(false/*, "Expected error for unclosed variable"*/);
    } catch e: TemplateStringError {
      test.assertEqual(e.message(), "Unclosed variable starting at position 6");
    } catch e {
      test.assertTrue(false/*, "Expected TemplateStringError, got " + e.message()*/);
    }
  }
  {
    var t = new templateString("Hello {{na!me}}!");
    try {
      t.fill(["na!me" => "world"]);
      test.assertTrue(false/*, "Expected error for invalid character in variable name"*/);
    } catch e: TemplateStringError {
      test.assertEqual(e.message(), "Invalid character in variable name: !");
    } catch e {
      test.assertTrue(false/*, "Expected TemplateStringError, got " + e.message()*/);
    }
  }
  {
    var t = new templateString("Hello {{}}!");
    try {
      t.fill(["a" => "world"]);
      test.assertTrue(false/*, "Expected error for empty variable name"*/);
    } catch e: TemplateStringError {
      test.assertEqual(e.message(), "Empty variable name at position 6");
    } catch e {
      test.assertTrue(false/*, "Expected TemplateStringError, got " + e.message()*/);
    }
  }
  {
    var t = new templateString("Hello @!", ("@", ""));
    try {
      t.fill(["b" => "world"]);
      test.assertTrue(false/*, "Expected error for empty variable name"*/);
    } catch e: TemplateStringError {
      test.assertEqual(e.message(), "Empty variable name at position 6");
    } catch e {
      test.assertTrue(false/*, "Expected TemplateStringError, got " + e.message()*/);
    }
  }
  {
    var t = new templateString("Hello @", ("@", ""));
    try {
      t.fill(["b" => "world"]);
      test.assertTrue(false/*, "Expected error for empty variable name"*/);
    } catch e: TemplateStringError {
      test.assertEqual(e.message(), "Empty variable name at position 6");
    } catch e {
      test.assertTrue(false/*, "Expected TemplateStringError, got " + e.message()*/);
    }
  }
  {
    var t = new templateString("Hello {{name}}!");
    try {
      t.fill(["na!me" => "world"]);
      test.assertTrue(false/*, "Expected error for variable not found in variables map"*/);
    } catch e: TemplateStringError {
      test.assertEqual(e.message(), "Variable 'name' not found in variables map");
    } catch e {
      test.assertTrue(false/*, "Expected TemplateStringError, got " + e.message()*/);
    }
  }
  {
    try {
      var t = new templateString("Hello {{name}}!", ("", "}}"));
    } catch e: TemplateStringError {
      test.assertEqual(e.message(), "Prefix cannot be empty");
    } catch e {
      test.assertTrue(false/*, "Expected TemplateStringError, got " + e.message()*/);
    }
  }
}


proc testCasts(test: borrowed Test) throws {
  var t: templateString = "Hello {{name}}!";
  var o = t(["name" => "world"]);
  test.assertEqual(o, "Hello world!");

  var t2: templateString = t;
  var o2 = t2(["name" => "world"]);
  test.assertEqual(o2, "Hello world!");

  var t3 = "Hello {{name}}!": templateString;
  var o3 = t3(["name" => "world"]);
  test.assertEqual(o3, "Hello world!");
}

UnitTest.main();

