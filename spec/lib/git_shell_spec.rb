require 'spec_helper'

describe GitShell do
  describe "create_app" do
    it "should create the bare repository"
    it "should create the working copy"
    it "should create an nginx config"
  end

  describe "update_app_keys" do
    it "should write all keys to the authkeys file"
  end

  describe "receive push" do
    it "should build the app and deploy it"
  end
end
