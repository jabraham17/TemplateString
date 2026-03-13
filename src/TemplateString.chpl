/*
  A simple template string implementation. Template strings are a more
  structured way to do string interpolation, where you can define a template
  with placeholders for variables, and then fill in those variables later.

  Example usage:

  .. code-block:: chapel

      var template: templateString = "Hello, {{name}}! Today is {{day}}.";
      var variables: map(string, string);
      variables["name"] = "Alice";
      variables["day"] = "Monday";
      var result = template(variables);
      writeln(result); // Output: Hello, Alice! Today is Monday.
*/
module TemplateString {
  use Map;


  /*
    The template string type. Template strings can either be implicitly created
    from string literals, or explicitly created with the constructor. The
    template string type has a single field, `template`, which is the template
    string itself. Variables in the template string are denoted by
    ``{{variableName}}`` by default, but this can be customized.

    .. code-block:: chapel

      var template =
        new templateString("Hello, <<name>>! Today is <<day>>.", ("<<", ">>"));
      var variables: map(string, string);
      variables["name"] = "Alice";
      variables["day"] = "Monday";
      var result = template(variables);
      writeln(result); // Output: Hello, Alice! Today is Monday.

  */
  record templateString {
    var template: string;
    @chpldoc.nodoc
    var variableWrapper: (string, string);
    @chpldoc.nodoc
    proc init(template: string) {
      this.template = template;
      this.variableWrapper = ("{{", "}}");
    }
    @chpldoc.nodoc
    proc init(template: string, variableWrapper: (string, string)) throws {
      this.template = template;
      this.variableWrapper = variableWrapper;
      init this;
      checkVariableWrapper();
    }

    @chpldoc.nodoc
    proc init=(other: templateString) {
      this.template = other.template;
      this.variableWrapper = other.variableWrapper;
    }
    @chpldoc.nodoc
    operator =(ref x: templateString, other: templateString) {
      x.template = other.template;
      x.variableWrapper = other.variableWrapper;
    }

    @chpldoc.nodoc
    proc init=(other: string) {
      this.template = other;
      this.variableWrapper = ("{{", "}}");
    }
    @chpldoc.nodoc
    operator =(ref x: templateString, other: string) {
      x.template = other;
      x.variableWrapper = ("{{", "}}");
    }
    @chpldoc.nodoc
    operator :(other: string, type t) where t == templateString {
      return new templateString(other);
    }

    @chpldoc.nodoc
    proc checkVariableWrapper() throws {
      const prefix = variableWrapper[0];
      const suffix = variableWrapper[1];
      if prefix.size == 0 {
        throw new TemplateStringError("Prefix cannot be empty");
      }
    }

    @chpldoc.nodoc
    proc isValidIdentChar(x: uint(8)) {
      return (x >= 'a'.toByte() && x <= 'z'.toByte()) ||
             (x >= 'A'.toByte() && x <= 'Z'.toByte()) ||
             (x >= '0'.toByte() && x <= '9'.toByte()) ||
              x == '_'.toByte() || x == '-'.toByte();
    }

    /*
      Fill in the template string with the provided variables, returning the
      result.

      :arg variables: The variables to fill the template with. This can either
                      be a :type:`Map.map` of strings to strings or an
                      associative array with string keys and string values.

      :throws TemplateStringError: If the template string is malformed (e.g.
                                   has an unclosed variable) or if a variable in
                                   the template string is not
                                   found in the variables map.
    */
    proc this(variables): string throws do
      return fill(variables);

    /*
      Fill in the template string with the provided variables, returning the
      result.

      :arg variables: A :type:`Map.map` of strings to strings, where the keys
                      are the variable names and the values are the
                      replacements.

      :throws TemplateStringError: If the template string is malformed (e.g.
                                   has an unclosed variable) or if a variable in
                                   the template string is not
                                   found in the variables map.
    */
    proc fill(variables: map(string, string)): string throws {

      const prefix = variableWrapper[0];
      const suffix = variableWrapper[1];

      var output = "";
      var i = 0;
      while i < template.size {
        // check if we are starting a variable
        if i + prefix.size <= template.size &&
           template[i..#prefix.size] == prefix {

          var varStart = i + prefix.size;
          var varEnd = varStart;
          var varName = "";
          if suffix.size == 0 {
            while varEnd < template.size &&
                  isValidIdentChar(template[varEnd].toByte()) {
              varEnd += 1;
            }
            if varEnd == varStart {
              throw new TemplateStringError(
                "Empty variable name at position " + i:string);
            }
            varName = template[varStart..<varEnd];
          } else {
            // the suffix can be 1+ characters, so we need to search for it
            while varEnd < template.size {
              if varEnd + suffix.size <= template.size &&
                 template[varEnd..#suffix.size] == suffix {
                break;
              }
              varEnd += 1;
            }
            if varEnd + suffix.size > template.size {
              throw new TemplateStringError(
                "Unclosed variable starting at position " + i:string);
            }
            varName = template[varStart..<varEnd];
            for c in varName {
              if !isValidIdentChar(c.toByte()) {
                throw new TemplateStringError(
                  "Invalid character in variable name: " + c);
              }
            }
          }
          if varName.size == 0 {
            throw new TemplateStringError(
              "Empty variable name at position " + i:string);
          }
          if !variables.contains(varName) {
            throw new TemplateStringError(
              "Variable '" + varName + "' not found in variables map");
          }
          output += variables[varName];
          i = varEnd + suffix.size;

        } else {
          output += template[i];
          i += 1;
        }
      }
      return output;
    }

    /*
      Fill in the template string with the provided variables, returning the
      result.

      :arg variables: An associative array with string keys and string values,
                      where the keys are the variable names and the values are
                      the replacements.

      :throws TemplateStringError: If the template string is malformed (e.g.
                                   has an unclosed variable) or if a variable in
                                   the template string is not
                                   found in the variables map.
    */
    proc fill(variables: [] string): string throws
      where variables.isAssociative() &&
           variables.domain.idxType == string {
      var variablesMap: map(string, string);
      for varName in variables.domain {
        variablesMap[varName] = variables[varName];
      }
      return fill(variablesMap);
    }
  }

  /*
    Error type for TemplateString errors
  */
  class TemplateStringError: Error {
    @chpldoc.nodoc
    proc init(message: string) {
      super.init(message);
    }
  }
}
