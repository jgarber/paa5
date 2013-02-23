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

  describe "#create_app" do
    it "should create the bare repository" do
      git_shell = GitShell.new('foo')
      git_shell.should_receive(:system).with("cd ./tmp/repositories/foo.git && git init --bare")
      git_shell.create_app
    end


  describe "receive push" do
    it "should build the app and deploy it"
  end
    it "should create the working copy"

    it "should create an nginx config"
  end
end
