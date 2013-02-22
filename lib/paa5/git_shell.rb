module Paa5
  class GitShell
    attr_reader :config

    def initialize
      @config = YAML.load_file(File.join(Rails.root, 'git.yml'))
    end
  end
end
