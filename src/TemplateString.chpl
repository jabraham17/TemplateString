/* Documentation for TemplateString */
module TemplateString {

  use Map;

  class TemplateStringError: Error {
    proc init(message: string) {
      super.init(message);
    }
  }

  record templateString {
    var template: string;
    var variableWrapper: (string, string);
    proc init(template: string) {
      this.template = template;
      this.variableWrapper = ("{{", "}}");
    }
    proc init(template: string, variableWrapper: (string, string)) throws {
      this.template = template;
      this.variableWrapper = variableWrapper;
      init this;
      checkVariableWrapper();
    }
    proc init=(other: templateString) {
      this.template = other.template;
      this.variableWrapper = other.variableWrapper;
    }
    operator =(ref x: templateString, other: templateString) {
      x.template = other.template;
      x.variableWrapper = other.variableWrapper;
    }
    proc init=(other: string) {
      this.template = other;
      this.variableWrapper = ("{{", "}}");
    }
    operator =(ref x: templateString, other: string) {
      x.template = other;
      x.variableWrapper = ("{{", "}}");
    }

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

    proc this(variables): string throws do
      return fill(variables);

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
}
