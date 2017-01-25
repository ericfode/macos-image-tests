require 'yaml'

module Simulators

  PATH = '../spec/fixtures/xcode/'

  class Xcode

    def initialize(name)
      @path = File.join(PATH, name)
    end

    def exists?
      File.file?(@path)
    end

    def present
      YAML::load(File.read(@path))
    end
  end

  class Generator < Jekyll::Generator

    def generate(site)
      puts(site.data.inspect)
      xcode = Dir.entries(PATH)
        .map    { |f| Xcode.new(f) }
        .select { |x| x.exists?    }
        .map    { |x| x.present    }
      site.data['xcode'] = xcode
      puts(xcode)
      puts(site.data.inspect)
    end

  end

end
