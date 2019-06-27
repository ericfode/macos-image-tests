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

def parse_cmd_kv_pairs(output)
  trimmed_pairs = output.lines
    .map {|s| s.split(':').map(&:strip).reject(&:empty?) }
    .reject {|a| a.count != 2}

  attributes = trimmed_pairs.each_with_object({}) do |(key, value), hash|
    # Convert keys into snake_case
    hash[key.downcase.split.join('_').gsub('-', '_').to_sym] = value
  end
end

def os()
  parse_cmd_kv_pairs `system_profiler SPSoftwareDataType`
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
  paths = `find /Applications -regex '/Applications/Xcode.*\.app' -maxdepth 1`.lines.map(&:strip).sort
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

def command_line_tools()
  parse_cmd_kv_pairs `pkgutil --pkg-info=com.apple.pkg.CLTools_Executables`
end

def homebrew()
  output = `brew list --versions`.lines.map(&:strip)
  output.each_with_object({}) do |line, h|
    name, *versions = line.split
    h[name] = versions
  end
end

def chruby_installed_rubies()
  # The output from chruby is like this:
  #    $ chruby
  #       ruby-2.2.8
  #     * ruby-2.3.5
  #       ruby-2.4.2
  #
  # `chruby` is a bash function, so we need to invoke bash as a login shell:
  `bash -lic chruby`.lines.map {|ruby| ruby.match(/ruby-(\S*)/)[1] }
end

def ruby()
  gem_versions = `gem list`.lines.select {|s| s.match(/^\S.* \(\S.*\)$/)}
  gems = gem_versions.map do |g|
    name, version = g.match(/(\S.*) \((\S.*)\)/).captures
    {name: name,
     version: version}
  end
  {
    system: output('ruby -v'),
    installed: chruby_installed_rubies,
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
    python3: output('python3   --version'),
    pip:     output('pip       --version'),
    pip3:    output('pip3      --version'),
    xctool:  output('xctool    --version'),
    parallel: output('parallel --version | head -n 1')
  }
end

def number_or_string(str)
  Integer(str)
rescue ArgumentError
  str
end

# Check if the screen is locked.
# Run some Python using the system python interpreter, which has access to
# Quartz (ObjectiveC). This prints a dictionary, which will contain a key
# 'CGSSessionScreenIsLocked' when the screen is locked, and the key will be
# absent otherwise. `system` returns true is the command succeeds, and `grep`
# will return success when it matches.
# Pipeout to /dev/null to prevent us printing to stdout.
def screen_locked?
  system("/usr/bin/python -c 'import sys,Quartz; d=Quartz.CGSessionCopyCurrentDictionary(); print d' | grep CGSSessionScreenIsLocked > /dev/null")
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
  power_settings: power_settings,
  command_line_tools: command_line_tools,
  screen_locked: screen_locked?
}

puts(JSON.pretty_generate(versions))
