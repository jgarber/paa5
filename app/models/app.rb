class App < ActiveRecord::Base
  attr_accessible :domains, :name, :key_ids
  attr_readonly :name

  validates :name, uniqueness: true, format: {with: /^[a-z0-9_-]+$/i, message: "Must be a valid git repo name" }
  has_and_belongs_to_many :keys

  after_create do
    GitShell.new(name).create_app
    create_database
    create_nginx_site
  end

  def push_url
    if keys.any?
      "#{name}.git"
    else
      "Add a public key to push to this repository"
    end
  end

  def create_nginx_site
    FileUtils.mkdir_p(sites_available, mode: 0755)
    FileUtils.mkdir_p(sites_enabled, mode: 0755)

    template = ERB.new(nginx_site_template)
    outfile = File.expand_path(File.join(sites_available, name))

    File.open(outfile, 'w') do |f|
      f.write template.result(binding)
    end
    File.chmod(0644, outfile)
    FileUtils.ln_s(outfile, File.join(sites_enabled, name), force: true)
  end

  def create_database
    system("DATABASE_URL=postgres://localhost/#{name} rake db:create")
  end

  private

  def nginx_server_names
    (domains || '').split("\n")
  end

  def apps_directory
    APP_CONFIG['apps_directory']
  end

  def sites_available
    File.join(nginx_config_dir, 'sites-available')
  end

  def sites_enabled
    File.join(nginx_config_dir, 'sites-enabled')
  end

  def nginx_site_template
    template = File.join(Rails.root, 'lib/templates/nginx_site.erb')
    File.new(template).read
  end

  def nginx_config_dir
    APP_CONFIG['nginx_config_directory']
  end
end
