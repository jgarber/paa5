require 'spec_helper'

describe GitShell do
  describe ".update_app_keys" do
    it "should write all keys to the authkeys file" do
      file = GitShell.config['authkeys_file']
      FileUtils.rm_f(file)
      keys = [create(:key), create(:key, name: "key 2")]
      GitShell.update_app_keys(keys)
      IO.readlines(file).each_with_index do |line, index|
        key = keys[index]
        line.should include(key.name)
        line.should include(key.body)
      end
    end
  end

  describe ".receive push" do
    let(:app) { create(:app_with_key) }
    let(:repo) { app.name }
    let(:key) { app.keys.first }
    let(:io) { mock(:stdout) }

    before do
      key_name(key.name)
      ssh_command("git-upload-pack")
    end

    it "should reject a non-existent key" do
      key_name('non-existent')
      should_be_rejected_with("Key non-existent not found.")
    end

    it "should reject a non-existent app" do
      ssh_command('git-upload-pack', 'non-existent')
      should_be_rejected_with("App non-existent not found.")
    end

    context "valid git command" do
      %w(git-upload-pack git-receive-pack git-upload-archive).each do |cmd|
        it "should proxy the #{cmd} git command through" do
          GitShell.any_instance.should_receive(:system) do |command|
            command.should include(cmd)
          end
          ssh_command(cmd)
          GitShell.receive_push
        end
      end

      it "should build the app and deploy it"
    end

    context "key not associated with app" do
      let(:key) { create(:key) }
      it "should reject the command" do
        should_be_rejected_with("You do not have access to app #{app.name}.")

      end
    end

    context "invalid git command" do
      it "should reject the command" do
        ssh_command("foo")
        should_be_rejected_with("You do not have permission to foo.")
      end
    end
  end

  describe "#create_app" do
    it "should create the bare repository" do
      git_shell = GitShell.new('foo')
      git_shell.should_receive(:system).with("cd ./tmp/repositories/foo.git && git init --bare")
      git_shell.create_app
    end

    it "should create the working copy"

    it "should create an nginx config"
  end

  def ssh_command(command, target=repo)
    ENV['SSH_ORIGINAL_COMMAND'] = "#{command} #{target}"
  end

  def key_name(name)
    ARGV[0] = name
  end

  def should_be_rejected_with(message)
    GitShell.any_instance.should_not_receive(:system)
    io.should_receive(:puts).with(message)

    GitShell.receive_push(io)
  end
end
