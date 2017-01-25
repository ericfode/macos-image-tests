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
      xcode = Dir.entries(PATH)
        .map    { |f| Xcode.new(f) }
        .select { |x| x.exists?    }
        .map    { |x| x.present    }
      site.data['xcode'] = xcode
      site.data['software'] = YAML::load(File.read('../spec/fixtures/software.yml'))
    end

  end

end
