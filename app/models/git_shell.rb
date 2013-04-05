class GitShell
  include Paths
  ALLOWED_COMMANDS = %w(git-upload-pack git-receive-pack git-upload-archive)
  attr_reader :name

  def self.update_app_keys(keys)
    lines = keys.map do |key|
      "command=\"#{Rails.root}/bin/git-shell '#{key.name}'\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty #{key.body}"
    end
    IO.write(APP_CONFIG['authkeys_file'], lines.join("\n"))
  end

  def self.receive_push(io=$stdout)
    key_name = ARGV.shift
    original_command = ENV['SSH_ORIGINAL_COMMAND']
    command, repo = original_command.split(' ')
    key = Key.find_by_name(key_name)
    app = App.find_by_name(repo)

    if key.nil?
      io.puts "Key #{key_name} not found."
    elsif app.nil?
      io.puts "App #{repo} not found."
    elsif key.in?(app.keys)
      new(repo).receive_push(command, io)
    else
      io.puts "You do not have access to app #{repo}."
    end
  end

  def initialize(app_name)
    @name = app_name
  end

  def create_app
    create_repository
    create_app_directory
  end

  def receive_push(command, io=$stdout)
    if command.in?(ALLOWED_COMMANDS)
      system("#{command} #{repo_path}")
    else
      io.puts "You do not have permission to #{command}."
    end
  end

  protected

  def create_repository
    FileUtils.mkdir_p(repo_path, mode: 0770)
    cmd = "cd #{repo_path} && git init --bare"
    system(cmd)
  end

  def create_app_directory
    FileUtils.mkdir_p(app_path, mode: 0770)
    Dir.chdir(app_path) do
      FileUtils.mkdir_p(%w(logs build releases shared))
    end
  end
end
