Pod::Spec.new do |spec|

  spec.name         = "ESPProvision"
  spec.version      = "2.1.1"
  spec.summary      = "ESP-IDF provisioning in Swift"
  spec.description  = "It provides mechanism to provide network credentials and/or custom data to an ESP32, ESP32-S2 or ESP8266 devices"
  spec.homepage     = "https://github.com/espressif/esp-idf-provisioning-ios"

  spec.license     = { :type => 'Apache License, Version 2.0',
                    :text => <<-LICENSE
                      Copyright © 2020 Espressif.
                      Licensed under the Apache License, Version 2.0 (the "License");
                      you may not use this file except in compliance with the License.
                      You may obtain a copy of the License at
                        http://www.apache.org/licenses/LICENSE-2.0
                      Unless required by applicable law or agreed to in writing, software
                      distributed under the License is distributed on an "AS IS" BASIS,
                      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
                      See the License for the specific language governing permissions and
                      limitations under the License.
                    LICENSE
                  }

  spec.author = "Espressif Systems"
  spec.platform = :ios, "13.0"
  spec.source = { :git => "https://github.com/espressif/esp-idf-provisioning-ios.git", :tag => "lib-#{spec.version}" }

  spec.source_files  = "ESPProvision", "ESPProvision/**/*.{h,m,swift}"


  spec.subspec 'Core' do |cs|
      cs.dependency "SwiftProtobuf", "~> 1.5.0"
      cs.dependency "Curve25519", "~> 1.1.0"
  end

  spec.swift_versions = ['5.1', '5.2']

end
