Pod::Spec.new do |s|
  s.name         = "Nodelike"
  s.version      = "0.1.0"
  s.summary      = "Node.js-compatible Framework for iOS"
  s.description  = <<-DESC
                   Nodelike implements a roughly Node.JS-compatible interface using JavaScriptCore.framework on iOS 7 and OS X Mavericks.
                   
                   (JavaScriptCore hasn't been available before iOS 7, and on OS X the project makes extensive use of the newly-updated 10.9-only Objective-C API. Previously on 10.8 there existed only a very low-level and very verbose C API.)
                   
                   The goals
                   ---------
                   - to be _drop-in compatible_ with the current nodejs master
                   - to be _very lightweight_
                   - to _reuse javascript code from node_ (/lib)
                   - to provide the _most minimal binding_ that is possible (via libuv)
                   - NOT to archieve Node.js performance (this is meant as a client-side, not a server-side application)
                   - NOT to be backwards-compatible (nodejs cutting edge and newest iOS/OS X required)
                   DESC
  s.homepage     = "http://nodeapp.org/"
  s.screenshots  = "https://raw.github.com/node-app/Nodelike/master/demo.gif"
  s.license      = 'Mozilla Public License Version 2.0'
  s.author       = { "Sam Rijs" => "recv@awesam.de" }
  s.source       = { :git => "https://github.com/node-app/Nodelike.git", :tag => s.version.to_s, :submodules => true }

  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.source_files = 'Nodelike/*.{h,m}', 'libuv/src/**/*.{c,h}', 'libuv/include/*.h'
  s.exclude_files = 'libuv/src/win', 'libuv/src/unix/*{bsd,aix,linux,sunos}*', 'libuv/include/uv-{bsd,linux,sunos,win}*.h','libuv/include/*msvc2008*.h' 
  s.frameworks = 'Foundation', 'JavaScriptCore'
  s.libraries = 'System'
  
end
