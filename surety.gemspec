Gem::Specification.new do |s|
  s.name              = 'surety'
  s.version           = '0.1.0'
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = 'A lightweight guaranteed-delivery messaging system.'
  s.homepage          = ''
  s.email             = 'monica@revolutionprep.com'
  s.authors           = ['Monica McArthur']

  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ['lib']

  s.add_dependency('resque', '>= 1.9.10')

  s.description       = <<-DESC
    A lightweight guaranteed-delivery messaging system.
  DESC
end
