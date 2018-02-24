# Wrap every HTML attributes by double quotes
Haml::Template.options[:attr_wrapper] = '"'

# Minify HTML in production
if Rails.env.production?
  Haml::Template.options[:remove_whitespace] = true
end
