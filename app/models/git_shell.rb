class GitShell
  attr_reader :config, :name

  def self.update_app_keys(keys)
    lines = keys.map do |key|
      "command=\"#{Rails.root}/bin/git-shell '#{key.name}'\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty #{key.body}"
    end
    IO.write(config['authkeys_file'], lines.join("\n"))
  end
  end

  def self.config
    YAML.load_file(File.join(Rails.root, 'config', 'git.yml'))[Rails.env]
  end

  def initialize(app_name)
    @config = self.class.config
    @name = app_name
  end

  def create_app
    create_repository
  end

  def receive_push

  end

  protected

  def create_repository
    FileUtils.mkdir_p(repo_path, mode: 0770)
    cmd = "cd #{repo_path} && git init --bare"
    system(cmd)
  end

  def create_working_copy
    FileUtils.mkdir_p(checkout_path, mode: 0770)
  end

  def repo_path
    File.join(config['repos_path'], name)
  end

  def checkout_path
    "/srv/#{name}"
  end
end
