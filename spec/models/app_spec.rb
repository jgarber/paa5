require 'spec_helper'

describe App do
  let(:app) { create(:app) }

  context "new App" do
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
        app.save
        app.reload.name.should_not == "bar"
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
end
