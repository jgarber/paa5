require 'spec_helper'

describe Deployment do
  let(:app) { create(:app) }
  subject { described_class.new(app.name) }

  it "should run mina setup" do
    FileUtils.rm_rf(app.app_path + '/current')
    subject.should_receive(:system) do |command|
      command.should match('setup')
    end

    subject.run
  end
end
