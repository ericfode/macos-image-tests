#!/usr/bin/env ruby
require 'open3'
require 'json'

# Run the given command and return stdout, stderr, and a boolean indicating if
# the command was successful.
def system3(*cmd)
  begin
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

def disk()
  (headers, values) = `df -H /`.lines.map(&:strip).map(&:split)
  Hash[headers.zip(values)]
end

def simulators(instruments_path)
  simulator_pattern = /(.*) \[(\S.*)\]/
  output =  output(instruments_path, '-s', 'devices').lines
  output = output.select {|s| s.match(simulator_pattern)}.map  do |s|
    s.match(simulator_pattern).captures.first
  end
  output = output.sort
end

def xcode()
  paths = `find /Applications -regex '/Applications/Xcode.*\.app' -maxdepth 1`.lines.map(&:strip)
  bundle_versions = paths.map do |path|
    plist = File.join(path, 'Contents', 'version.plist')
    bindir = File.join(path, 'Contents', 'Developer', 'usr', 'bin')
    instruments = File.join(bindir, 'instruments')
    xcodebuild  = File.join(bindir, 'xcodebuild')
    { version:       output('defaults', 'read', plist, 'CFBundleShortVersionString'),
      build_version: output('defaults', 'read', plist, 'ProductBuildVersion'),
      license_accepted: `#{xcodebuild} -checkFirstLaunchStatus ; echo $?`.to_i == 0,
      tools_installed: `sudo xcode-select -s #{path} && xcode-select --print-path > /dev/null ; echo $?`.to_i == 0,
      simulators: simulators(instruments),
      app_location: path
    }
  end
  bundle_versions
end

def homebrew()
  output = `brew list --versions`.lines.map(&:strip)
  output.each_with_object({}) do |line, h|
    name, *versions = line.split
    h[name] = versions
  end
end

def ruby()
  gem_versions = `gem list`.lines.select {|s| s.match(/^\S.* \(\S*\)$/)}
  gems = gem_versions.map do |g|
    name, version = g.match(/(\S.*) \((\S.*)\)/).captures
    {name: name,
     version: version}
  end
  {
    version: output('chruby').split("\n").join(", "),
    gems: gems
  }
end

def environment()
  { keyboard_layout: output('defaults read /Library/Preferences/com.apple.HIToolbox.plist  AppleCurrentKeyboardLayoutInputSourceID'),
    timezone: output('date +%Z'),
    screensaver_ask_for_password: output('defaults read com.apple.screensaver askForPassword'),
  }
end

def tools()
  {
    java:    output('java       -version 2>&1'),
    python:  output('python    --version 2>&1'),
    pip:     output('pip       --version'),
    xctool:  output('xctool    --version'),
    parallel: output('parallel --version | head -n 1')
  }
end

def number_or_string(str)
  Integer(str)
rescue ArgumentError
  str
end

def power_settings()
  #  $ sudo pmset -g
  # Currently in use:
  #  standbydelay         10800
  #  standby              1
  #  halfdim              1
  #  etc..

  # Convert output to an array of key/value pairs
  pairs = output('sudo pmset -g | grep "^ .*"').lines.map(&:split)

  # Convert any number looking values to integers, else strings.
  pairs.each_with_object({}) do |(key, value), hash|
    hash[key] = number_or_string(value)
  end
end

def image_info
  raw = File.readlines("#{Dir.home}/.circle_image")
    .map(&:strip)
    .reject(&:empty?)
    .map {|s| s.split(': ')}
  raw.each_with_object({}) do |(key, value), hash|
    hash[key.downcase] = value
  end
end

versions = {
  image: image_info,
  os: os,
  disk: disk,
  environment: environment,
  tools: tools,
  ruby: ruby,
  homebrew: homebrew,
  xcode: xcode,
  power_settings: power_settings
}

puts(JSON.pretty_generate(versions))
