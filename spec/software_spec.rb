require 'spec_helper'
require 'rspec_candy/matchers'
require 'json'
require 'yaml'

describe 'vm image' do

  software = JSON.parse(File.read(ENV['SOFTWARE']))
  expected_gems = YAML::load(File.read('spec/fixtures/gems.yml'))
  expected_formulae = YAML::load(File.read('spec/fixtures/homebrew.yml'))
  expected_disk = YAML::load(File.read('spec/fixtures/disk.yml'))
  expected_clt = YAML::load(File.read('spec/fixtures/clt.yml'))

  describe 'system settings' do
    expected = YAML::load(File.read('spec/fixtures/software.yml'))
    expected.each do |key, value|

      it "has the correct #{key}" do
        expect(software[key]).to include_hash(value)
      end

    end
  end

  describe 'physical disk' do
    expected_disk.each do |key, value|
      it "has the expected df #{key} output" do
          expect(software['disk'][key]).to eq(value), "Expected disk[#{key}] to be '#{value}', got #{software['disk'][key]}"
      end
    end
  end

  describe 'gems' do
    installed = software['ruby']['gems'].each_with_object({}) do |gem, hsh|
      hsh[gem['name']] = gem['version']
    end
    expected_gems.each do |gem, version|
      installed_gem = installed[gem]
      it "has the right version of #{gem}" do
        expect(installed_gem).to eq(version), lambda { "expected #{gem} to be version #{version} but got #{installed_gem}"}
      end
    end
  end

  describe 'homebrew' do
    installed = software['homebrew'].each_with_object({}) do |(name, versions), hsh|
      hsh[name] = versions
    end
    expected_formulae.each do |name, versions|
      it "has the right version of #{name}" do
        expect(installed[name]).to eq(versions), lambda { "expected #{name} to have versions #{versions} but got #{installed[name]}"}
      end
    end
  end

  it 'has the screen unlocked' do
    expect(software['screen_locked']).to be false
  end

  it 'has the correct command line tools' do
    expect(software['command_line_tools']).to include_hash(expected_clt)
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
    let(:expected) { YAML::load(File.read('spec/fixtures/xcode/xcode.yml')) }
    let(:actual) { software['xcode'] }

    it 'is the correct build' do
      expect(actual['version']).to eq(expected['version'])
      expect(actual['build_version']).to eq(expected['build_version'])
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
      expect(actual['app_location']).to eq(expected['app_location'])
    end

  end
end
