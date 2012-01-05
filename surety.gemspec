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

  s.add_dependency('yajl-ruby', '~> 0.8.2')
  s.add_dependency('resque', '>= 1.19.0')
  s.add_dependency('activesupport', '>= 3.0')
  s.add_dependency('activerecord', '>= 3.0')
  s.add_dependency('state_machine', '>=1.0.0')

  s.add_development_dependency('mysql2', '0.2.7')

  s.description       = <<-DESC
    A lightweight guaranteed-delivery messaging system.
  DESC
end
