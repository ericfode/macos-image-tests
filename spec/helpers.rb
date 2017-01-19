module Helpers

  # Load the simulators for the given xcode version.
  # Return an array that matched the JSON output format.
  def simulators(version)
    File.readlines("spec/fixtures/simulators/#{version}").map do |name|
      { name: name.strip }
    end.unshift({}) # Add an empty slot at the front to handle the `distiller` simulator.
  end
end