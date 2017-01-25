require 'spec_helper'
require 'rspec_candy/matchers'
require 'json'
require 'yaml'

describe 'software' do

  let(:software) { JSON.parse(File.read(ENV['SOFTWARE'])) }
  let(:expected_gems) { YAML::load(File.read('spec/fixtures/gems.yml')) }

  it 'has an os' do
    expected = YAML::load(File.read('spec/fixtures/software.yml'))
    keys = expected.each do |key, value|
      expect(software[key]).to include_hash(value)
    end

  end
  
  it 'has the right gems' do
    
    installed = software['ruby']['gems'].each_with_object({}) do |gem, hsh|
      hsh[gem['name']] = gem['version']
    end

    expected_gems.each do |gem, version|
      expect(installed[gem]).to eq(version), lambda { "expected #{gem} to be version #{version} but got #{installed[gem]}"}
    end
    
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

  Dir.glob('spec/fixtures/xcode/xcode_*.yml')
    .each_with_index do |version, i|

     it "#{version} has all simulators" do

       expected = YAML::load(File.read(version))
       actual = software['xcode'][i]

       expect(expected['version']).to eq(actual['version'])
       expect(expected['build_version']).to eq(actual['build_version'])

       expected_names =  expected['simulators'] + [software['os']['computer_name']]

       expect(actual['simulators']).to match_array(expected_names)

     end
   end

end
