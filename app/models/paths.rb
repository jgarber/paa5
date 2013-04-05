module Paths
  def repo_path
    File.join(APP_CONFIG['repos_path'], name + '.git')
  end

  def app_path
    File.join(apps_directory, name)
  end

  def apps_directory
    APP_CONFIG['apps_directory']
  end

  def app_env_path
    File.join(app_path, 'shared', '.env')
  end

  def sites_available
    File.join(nginx_config_dir, 'sites-available')
  end

  def sites_enabled
    File.join(nginx_config_dir, 'sites-enabled')
  end

  def nginx_config_dir
    APP_CONFIG['nginx_config_directory']
  end

end
