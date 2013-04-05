require 'spec_helper'

describe App do
  subject { create(:app) }

  describe "create app" do
    it "creates the repository" do
      GitShell.any_instance.should_receive(:create_app)
      create(:app)
    end

    it "create the app database" do
      name = "app_with_database"
      App.any_instance.should_receive(:system).with("DATABASE_URL=postgres://localhost/#{name} rake db:create")
      create(:app, name: name)
    end

    it "creates the nginx site config" do
      nginx_dir = APP_CONFIG['nginx_config_directory']
      site_available = File.join(nginx_dir, 'sites-available', 'foo')
      site_enabled = File.join(nginx_dir, 'sites-enabled', 'foo')
      [site_available, site_enabled].each {|f| FileUtils.rm_rf(f) }

      create(:app, name: 'foo')
      File.exist?(site_available).should be_true
      File.identical?(site_available, site_enabled).should be_true
    end
  end

  context "new App" do
    let(:app) { create(:app) }

    describe :name do
      it "is required" do
        build(:app, name: '').should_not be_valid
      end

      it "should be unique" do
        build(:app, name: app.name).should_not be_valid
      end

      it "should not contain spaces" do
        build(:app, name: "foo bar").should_not be_valid
      end

      it "should not be renameable" do
        app.name = "bar"
        app.update_attributes(name: "bar")
        app.name.should_not == "bar"
      end
    end

    it "should be valid without domains" do
      app.domains = ""
      app.should be_valid
    end

    it "should not have a push URL" do
      app.push_url.should == "Add a public key to push to this repository"
    end
  end

  context "with one or more keys" do
    let(:app) { create(:app_with_key) }

    it "should have a push URL" do
      app.push_url.should match(app.name)
    end
  end

  describe "environment variables" do
    it "should have a default set of config vars" do
      subject.env['DATABASE_URL'].should_not be_nil
      subject.env['RACK_ENV'].should_not be_nil
    end

    it "should mirror RACK_ENV to RAILS_ENV" do
      subject.env['RAILS_ENV'].should == subject.env['RACK_ENV']
    end

    it "should save env" do
      subject.env['FOO_BAR'] = 'foo bar'
      subject.save
      subject.env['FOO_BAR'] = nil # not saved
      subject.reload.env['FOO_BAR'].should == 'foo bar'
    end
  end

  describe "database_url" do
    it "should mirror the environment variable" do
      new_url = "something different"
      subject.env['DATABASE_URL'] = new_url
      subject.database_url.should == new_url
    end
  end
end
