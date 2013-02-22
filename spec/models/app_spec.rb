require 'spec_helper'

describe App do
  let(:app) { create(:app) }

  context "new App" do
    it "should not have a push URL" do
      app.push_url.should == "Add a public key to push to this repository"
    end
  end

  context "with one or more keys" do
    it "should have a push URL"
  end
end
