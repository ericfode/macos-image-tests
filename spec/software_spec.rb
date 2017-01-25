require 'spec_helper'
require 'rspec/json_expectations'
require 'json'

describe 'software' do

  let(:software) { JSON.parse(File.read(ENV['SOFTWARE'])) }

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

  ['xcode_70.yml',
   'xcode_71.yml',
   'xcode_72.yml',
   'xcode_73.yml',
   'xcode_80.yml',
   'xcode_81.yml',
   'xcode_821.yml'].each_with_index do |version, i|

     it "#{version} has all simulators" do

      expected_names =  xcode(version)['simulators'].map {|s| s['name']} + [software['os']['computer_name']]

      expect(software['xcode'][i]['simulators'].map {|s| s['name']} ).to match_array(expected_names)

     end
  end
  
end
