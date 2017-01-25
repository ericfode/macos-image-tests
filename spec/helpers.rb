require 'yaml'

module Helpers
  # Load the expected data for each version of xcode
  def xcode(version)
    YAML::load(File.read("spec/fixtures/xcode/#{version}"))
  end
end