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
    instruments = File.join(path, 'Contents', 'Developer', 'usr', 'bin', 'instruments')
    { version:       output('defaults', 'read', plist, 'CFBundleShortVersionString'),
      build_version: output('defaults', 'read', plist, 'ProductBuildVersion'),
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
    version: output('ruby -v'),
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
    java:   output('java    -version 2>&1'),
    python: output('python --version 2>&1'),
    xctool: output('xctool --version'),
  }
end

versions = {
  os: os,
  environment: environment,
  tools: tools,
  ruby: ruby,
  homebrew: homebrew,
  xcode: xcode,
}

puts(JSON.pretty_generate(versions))
