#!/usr/bin/env ruby
require 'pp'
require 'open3'
require 'yaml'

# Run the given command and return stdout, stderr, and a boolean indicating if
# the command was successful.
def system3(*cmd)
  begin
    puts("$ #{cmd.join(' ')}")
    stdout, stderr, status = Open3.capture3(*cmd)
    [stdout, stderr, status.success?]
  rescue
    [$/, $/, nil]
  end
end


# Return the output of the given command, or the symbol :error on failure.
def output(*cmd)
  out, err, success = system3(*cmd)
  success ? out.strip : :error
end

def os()
  output = `system_profiler SPSoftwareDataType`
  trimmed_pairs = output.lines
    .map {|s| s.split(':').map(&:strip).reject(&:empty?) }
    .reject {|a| a.count != 2}

  attributes = trimmed_pairs.each_with_object({}) do |(key, value), hash|
    hash[key.downcase.split.join('_').to_sym] = value
  end
end

def xcode()
  versions = `ls /Applications/Xcode*/Contents/version.plist`.lines.map(&:strip)
  bundle_versions = versions.map do |path|
    {version:       output('defaults', 'read', path, 'CFBundleShortVersionString'),
     build_version: output('defaults', 'read', path, 'ProductBuildVersion')}
  end
  bundle_versions
end


def simulators()
  output = `instruments -s devices`.lines
  lines = output.map(&:strip).select {|s| s.match(/\(Simulator\)$/)}
  lines.map do |s|
    name, uuid = s.match(/(.*) \[(\S.*)\]/).captures
    { name: name,
      uuid: uuid }
  end
end


def tools()
  {
    ruby: output('ruby -v'),
    python: output('python --version 2>&1'),
    xctool: output('xctool --version'),
    cocoapods: output('pod --version'),
    xcpretty: output('xcpretty --version'),
    fastlane: output('fastlane --version'),
    carthage: output('carthage version'),
    shenzhen: output('ipa --version'),
  }
end

versions = {
  os: os,
  tools: tools,
  xcode: xcode,
  simulators: simulators
}

puts(versions.to_yaml)
