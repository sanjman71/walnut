if RUBY_VERSION.to_f == 1.8
  class BlankSlate #:nodoc:
    instance_methods.each { |m| undef_method m unless m =~ /^__|instance_eval|object_id/ }
  end
else
  # class BlankSlate < BasicObject; end
  # BlankSlate already defined in ruby 1.9
end
 
# 1.8.6 has mistyping of transitive in if statement
require "rexml/document"
module REXML #:nodoc:
  class Document < Element #:nodoc:
    def write( output=$stdout, indent=-1, transitive=false, ie_hack=false )
      if xml_decl.encoding != "UTF-8" && !output.kind_of?(Output)
        output = Output.new( output, xml_decl.encoding )
      end
      formatter = if indent > -1
          if transitive
            REXML::Formatters::Transitive.new( indent, ie_hack )
          else
            REXML::Formatters::Pretty.new( indent, ie_hack )
          end
        else
          REXML::Formatters::Default.new( ie_hack )
        end
      formatter.write( self, output )
    end
  end
end
