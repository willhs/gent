Gem::Specification.new do |spec|
  spec.name          = "gent"
  spec.version       = "0.1.0"
  spec.authors       = ["Will"]
  spec.email         = ["whardwicksmith@gmail.com"]

  spec.summary       = "Configuration management for AI development tools"
  spec.description   = "Centralized configuration management for Claude, Windsurf, Codex and other AI tools"
  spec.homepage      = "https://github.com/willhs/gent"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "config/*", "README.md", "CLAUDE.md"]
  spec.bindir        = "bin"
  spec.executables   = ["gent"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.6.0"
  
  spec.add_runtime_dependency "toml-rb", "~> 2.0"
end
