require 'rspec/json_expectations'

describe 'python' do

  let(:software) { File.read(ENV['SOFTWARE']) }

  it 'works' do
    expect(software).to include_json(
      os:  {
        "system_version": "OS X 10.11.6 (15G1108)",
        "kernel_version": "Darwin 15.6.0",
        "boot_volume": "Macintosh HD",
        "boot_mode": "Normal",
        "user_name": "Distiller (distiller)",
        "secure_virtual_memory": "Enabled",
        "system_integrity_protection": "Enabled",
      }
    )

  end
end
