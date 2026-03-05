import TemplateString.{templateString,TemplateStringError};

var myTemplate: templateString = """
    Hello {{name}}!
    Your name is {{name}} and your favorite color is {{color}}.
  """.dedent().strip(trailing=false);

var variables = ["name" => "Alice", "color" => "blue"];
try! {
  var result = myTemplate.fill(variables);
  writeln(result);
} catch e: TemplateStringError {
  writeln("Error filling template: " + e.message());
}
