require "yaml"
require "json"

class LibGenerator::Library
  getter name : String
  getter ldflags : String
  getter cflags : String?
  getter includes : Array(String)?
  getter definitions : Hash(String, LibGenerator::Definition)?
  getter packages : String?
  getter destdir : String?
  getter rename : LibGenerator::RenameTransformer?

  {% for klass in ["YAML", "JSON"] %}
  {{klass.id}}.mapping({
    name:        {type: String},
    ldflags:     {type: String},
    cflags:      {type: String, nilable: true},
    includes:    {type: Array(String), nilable: true},
    definitions: {type: Hash(String, LibGenerator::Definition), nilable: true},
    packages:    {type: String, nilable: true},
    destdir:     {type: String, nilable: true},
    rename:      {type: LibGenerator::RenameTransformer, nilable: true},
  })
  {% end %}

  def self.new(pc : YAML::ParseContext, n : YAML::Nodes::Node)
    previous_def.tap(&.check_attr!)
  end

  def initialize(pp : JSON::PullParser)
    previous_def
    check_attr!
  end

  def initialize(@name : String, @ldflags : String, @includes = nil, @definitions = nil, @cflags = nil, @packages = nil, @destdir = nil, @rename = nil)
    check_attr!
  end

  protected def check_attr!
    if (@includes.nil? || @includes.try(&.empty?)) && (@definitions.nil? || @definitions.try(&.empty?))
      raise ArgumentError.new(%("includes" or "definitions" must be defined))
    end
  end

  def destdir : String
    @destdir ||= File.join("src", @name.underscore)
  end

  def generate_cflags : String?
    cflags = @cflags
    if (packages = @packages)
      pcflags = `command -v pkg-config > /dev/null \
                 && pkg-config --cflags #{packages} 2> /dev/null`.strip
      if pcflags.empty?
        cflags
      elsif (cflags.nil? || cflags.empty?)
        pcflags
      elsif (cflags.strip == pcflags)
        pcflags
      else
        "#{pcflags} #{cflags}"
      end
    else
      cflags
    end
  end

  def generate_ldflags : String
    ldflags = @ldflags
    if (packages = @packages)
      "`command -v pkg-config > /dev/null " \
      "&& pkg-config --libs #{packages} 2> /dev/null" \
      "|| printf %s '#{ldflags}'`"
    else
      ldflags
    end
  end
end
