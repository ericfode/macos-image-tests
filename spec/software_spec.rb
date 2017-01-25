require 'spec_helper'
require 'rspec/json_expectations'

describe 'software' do

  let(:software) { File.read(ENV['SOFTWARE']) }

  it 'has an os' do
    expect(software).to include_json(
      os:  {
        system_version: "OS X 10.11.6 (15G1108)",
        kernel_version: "Darwin 15.6.0",
        boot_volume: "Macintosh HD",
        boot_mode: "Normal",
        user_name: "Distiller (distiller)",
        secure_virtual_memory: "Enabled",
        system_integrity_protection: "Enabled",
      },
      environment: {
        keyboard_layout: "com.apple.keylayout.US",
        timezone: "PST",
        screensaver_ask_for_password: "0"
      },
      tools: {
        python: "Python 2.7.10",
        xctool: "0.2.9"
      },
    )
  end


  # TODO:
  # https://www.relishapp.com/waterlink/rspec-json-expectations/docs/json-expectations/array-matching-support-for-include-json-matcher#expecting-wrong-json-string-with-array-at-root-to-fully-include-json-with-arrays
  # There is a strange issue with include_json:
  # It seems to allow fewer elements in the expected array versus the given input.
  # So expect
  #   foo: [1,2,3,4]
  # to include_json
  #   foo: [1,2,3]
  # will pass.
  # This means if a new simulator appears in the image at the end of the simulators
  # list, and we don't expect it, these tests will still pass.
  it 'has xcode' do
    expect(software).to include_json(
      xcode: [{
        version: "7.0",
        build_version: "7A220",
        simulators: simulators('xcode_70.yml')
      }, {
        version: "7.1",
        build_version: "7B91b",
        simulators: simulators('xcode_71.yml')
      }, {
        version: "7.2",
        build_version: "7C68",
        simulators: simulators('xcode_72.yml')
      }, {
        version: "7.3",
        build_version: "7D175",
        simulators: simulators('xcode_73.yml')
      }, {
        version: "8.0",
        build_version: "8A218a",
        simulators: simulators('xcode_80.yml')
      }, {
        version: "8.1",
        build_version: "8B62",
        simulators: simulators('xcode_81.yml')
      }, {
        version: "8.2.1",
        build_version: "8C1002",
        simulators: simulators('xcode_821.yml')
      }]
    )
  end
  
end
