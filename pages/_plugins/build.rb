module Simulators

  PATH = '../spec/fixtures/simulators/'

  class Xcode

    attr_reader :name

    def initialize(name)
      @name = name
      @path = File.join(PATH, @name)
    end

    def simulators
      File.readlines(@path)
    end

    def exists?
      File.file?(@path)
    end

    def present
      {
        "name" => @name,
        "simulators" => simulators
      }
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
      puts(site.data.inspect)
    end

  end

end
