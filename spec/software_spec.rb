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

  it 'has xcode' do
    expect(software).to include_json(
      xcode: [{
        version: "7.0",
        build_version: "7A220"
      }, {
        version: "7.1",
        build_version: "7B91b"
      }, {
        version: "7.2",
        build_version: "7C68"
      }, {
        version: "7.3",
        build_version: "7D175"
      }, {
        version: "8.0",
        build_version: "8A218a"
      }, {
        version: "8.1",
        build_version: "8B62"
      }, {
        version: "8.2.1",
        build_version: "8C1002"
      }]
    )
  end
end
