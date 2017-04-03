require 'spec_helper'
require 'rspec_candy/matchers'
require 'json'
require 'yaml'

describe 'vm image' do

  let(:software) { JSON.parse(File.read(ENV['SOFTWARE'])) }
  let(:expected_gems) { YAML::load(File.read('spec/fixtures/gems.yml')) }
  let(:expected_formulae) { YAML::load(File.read('spec/fixtures/homebrew.yml')) }

  describe 'system settings' do
    expected = YAML::load(File.read('spec/fixtures/software.yml'))
    expected.each do |key, value|

      it "has the correct #{key}" do
        expect(software[key]).to include_hash(value)
      end

    end
  end


  it 'has the right gems' do
    installed = software['ruby']['gems'].each_with_object({}) do |gem, hsh|
      hsh[gem['name']] = gem['version']
    end
    expected_gems.each do |gem, version|
      installed_gem = installed[gem]
      expect(installed_gem).to eq(version), lambda { "expected #{gem} to be version #{version} but got #{installed_gem}"}
    end
  end

  it 'has the right homebrew formulae' do
    installed = software['homebrew'].each_with_object({}) do |(name, versions), hsh|
      hsh[name] = versions
    end
    expected_formulae.each do |name, versions|
      expect(installed[name]).to eq(versions), lambda { "expected #{name} to have versions #{versions} but got #{installed[name]}"}
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

  describe 'xcode' do
    Dir.glob('spec/fixtures/xcode/xcode_*.yml')
      .each_with_index do |version, i|

      describe version do
        let(:expected) { YAML::load(File.read(version)) }
        let(:actual) { software['xcode'][i] }

        it 'is the correct build' do
          expect(expected['version']).to eq(actual['version'])
          expect(expected['build_version']).to eq(actual['build_version'])
        end

        it 'has license accepted and tools installed' do
          expect(actual['license_accepted']).to be true
          expect(actual['tools_installed' ]).to be true
        end

        it 'has all simulators' do
          expected_names =  expected['simulators'] + [software['os']['computer_name']]

          expect(actual['simulators']).to match_array(expected_names)
        end

        it 'is in the correct location' do
          expect(expected['app_location']).to eq(actual['app_location'])
        end

        it 'can be selected as the current xcode' do
          `sudo xcode-select --switch #{actual['app_location']}`
          expect($?).to eq(0)
        end
      end
    end
  end
end
