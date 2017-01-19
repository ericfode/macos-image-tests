module Helpers
  def simulators(version)
   File.readlines("spec/fixtures/simulators/#{version}").map do |name|
       {
           name: name.strip
        }
    end
  end
end