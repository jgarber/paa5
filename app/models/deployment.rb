class Deployment
  include Paths
  attr_reader :app

  # sudo mkdir -p "/srv/paa5" && sudo chown -R vagrant "/srv/paa5"
  # bash < <(bundle exec mina -S -v setup | head --lines=-1)
  # bash < <(bundle exec mina -S -v deploy | head --lines=-1)
  def initialize(app)
    @app = app
  end

  def run
    unless Dir.exists?(File.join(app.app_path, "current"))
      mina_local("setup")
    end
  end

  def mina_local(command_str)
    system("bash < <(bundle exec mina #{command_str} | head --lines=-1)")
  end
end
