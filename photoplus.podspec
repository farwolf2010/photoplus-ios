

Pod::Spec.new do |s|

 
  s.platform  = :ios, "8.0"
  s.name         = "photoplus"
  s.version      = "1.0.1"
  s.summary      = "weexplus相机库"
  s.description  = <<-DESC
                     weexplus相机库.
                   DESC

  s.homepage     = "https://farwolf2010.github.io/doc"
  s.license      = "MIT"
  s.author             = { "zjr" => "362675035@qq.com" }
  s.source       = { :git => "https://github.com/farwolf2010/photoplus.git", :tag => "1.0.1" }
  s.source_files  = "Source", "**/**/*.{h,m,mm,c}"
  s.resources = "resources/*",'TZImagePickerController/*.{png,bundle}'
  # s.ios.vendored_libraries = '*.a'
  # s.ios.vendored_frameworks = '*.framework'

  s.exclude_files = "Source/Exclude"
  s.dependency 'farwolf.weex' , '~> 1.0.2'
  # s.dependency 'farwolf.weex', :git => 'https://github.com/farwolf2010/farwolf.weex'
  s.frameworks   = "Photos", "CoreServices"
  s.dependency 'GPUImage'
  s.dependency 'ZLPhotoBrowser'
 
 


 
  
  #s.frameworks =  'UIKit'
  #s.libraries = "z", "c++"
  #s.requires_arc  = true
    

end
