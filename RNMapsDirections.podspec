require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "RNMapsDirections"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = "https://github.com/bramus/react-native-maps-directions"
  s.author       = { 
      "bramus"   => "https://www.bram.us/",
      "goodbag"  => "https://goodbag.io",
      "Kiwi.com" => "https://github.com/kiwicom"
  }
  s.license      = "MIT"
  s.platform     = :ios, "10.0"
  s.source       = { :git => "https://github.com/bramus/react-native-maps-directions.git", :tag => "#{s.version}" }

  s.source_files  = "ios/**/*.{h,m}"

  s.dependency "React"
end
  