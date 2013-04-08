class Deployment
  include Paths
  attr_reader :name

  # sudo mkdir -p "/srv/paa5" && sudo chown -R vagrant "/srv/paa5"
  # bash < <(bundle exec mina -S -v setup | head --lines=-1)
  # bash < <(bundle exec mina -S -v deploy | head --lines=-1)
  def initialize(name)
    @name = name
  end

  def run
    unless Dir.exists?(File.join(app_path, "current"))
      mina_local("setup") && mina_local("deploy")
    end
  end

  def mina_local(command_str)
    script = `bundle exec mina #{command_str} -S -v -f #{deploy_rb} | head --lines=-1`
    system(script)
  end

  def deploy_rb
    file = Tempfile.new('deploy')
    FileUtils.cd(repo_path) do
      output=`git show HEAD:config/deploy.rb`
      if $?.success?
        file.write(output)
      else
        raise NotImplementedError, "default deploy.rb isn't implemented yet" # FIXME
      end
    end
    file.path
  ensure
    file.close
  end
end
