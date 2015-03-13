# Wrap every HTML attributes by double quotes
Haml::Template.options[:attr_wrapper] = '"'

# Override tag helper from Rails to disable self-closing tags
module ActionView
  class Base
    def tag(name, options = nil, open = false, escape = true)
      tag_string = "<#{name}#{tag_options(options, escape) if options}>"
      tag_string.respond_to?('html_safe') ? tag_string.html_safe : tag_string
    end
  end
end

# Override Haml build_attributes method to avoid attributes ordering
module Haml
  class Compiler
    def self.build_attributes(is_html, attr_wrapper, escape_attrs, hyphenate_data_attrs, attributes = {})
      quote_escape     = attr_wrapper == '"' ? "&#x0022;" : "&#x0027;"
      other_quote_char = attr_wrapper == '"' ? "'" : '"'
      join_char        = hyphenate_data_attrs ? '-' : '_'

      attributes.each do |key, value|
        if value.is_a?(Hash)
          data_attributes = attributes.delete(key)
          data_attributes = flatten_data_attributes(data_attributes, '', join_char)
          data_attributes = build_data_keys(data_attributes, hyphenate_data_attrs, key)
          attributes = data_attributes.merge(attributes)
        end
      end

      result = attributes.collect do |attr, value|
        next if value.nil?

        value = filter_and_join(value, ' ') if attr == 'class'
        value = filter_and_join(value, '_') if attr == 'id'

        if value == true
          next " #{attr}" if is_html
          next " #{attr}=#{attr_wrapper}#{attr}#{attr_wrapper}"
        elsif value == false
          next
        end

        escaped =
          if escape_attrs == :once
            Haml::Helpers.escape_once(value.to_s)
          elsif escape_attrs
            Haml::Helpers.html_escape(value.to_s)
          else
            value.to_s
          end
        value = Haml::Helpers.preserve(escaped)
        if escape_attrs
          value.gsub!(/&quot;|&#x0022;/, '"')
          this_attr_wrapper = attr_wrapper
          if value.include? attr_wrapper
            if value.include? other_quote_char
              value.gsub!(attr_wrapper, quote_escape)
            else
              this_attr_wrapper = other_quote_char
            end
          end
        else
          this_attr_wrapper = attr_wrapper
        end
        " #{attr}=#{this_attr_wrapper}#{value}#{this_attr_wrapper}"
      end
      # Removed .sort
      result.compact.join
    end
  end
end
