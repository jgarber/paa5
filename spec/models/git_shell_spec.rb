require 'spec_helper'

describe GitShell do
  describe "create_app" do
    it "should create the bare repository" do
      git_shell = GitShell.new('foo')
      git_shell.should_receive(:system).with("cd ./tmp/repositories/foo && git init --bare")
      git_shell.create_app
    end

    it "should create the working copy"

    it "should create an nginx config"
  end

  describe "update_app_keys" do
    it "should write all keys to the authkeys file" do
      file = GitShell.config['authkeys_file']
      FileUtils.rm_f(file)
      keys = ["abc", "123"]
      GitShell.update_app_keys(keys)
      IO.readlines(file).map(&:chomp).should == keys
    end
  end

  describe "receive push" do
    it "should build the app and deploy it"
  end
end
