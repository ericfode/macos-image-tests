require 'yaml'

module Helpers

  # Load the simulators for the given xcode version.
  # Return an array that matched the JSON output format.
  def simulators(version)
    xcode = YAML::load(File.read("spec/fixtures/xcode/#{version}"))
    xcode['simulators'].map do |name|
      { name: name }
    end.unshift({}) # Add an empty slot at the front to handle the `distiller` simulator.
  end
end