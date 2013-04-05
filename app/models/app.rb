require "foreman/env"

class App < ActiveRecord::Base
  include Paths
  attr_accessible :domains, :name, :key_ids
  attr_reader :env

  validates :name, uniqueness: true, format: {with: /^[a-z0-9_-]+$/i, message: "Must be a valid git repo name" }
  has_and_belongs_to_many :keys

  after_create do
    GitShell.new(name).create_app
    create_database
    create_nginx_site
  end
  after_save :write_app_env
  after_initialize :load_app_env

  def push_url
    if keys.any?
      "#{name}.git"
    else
      "Add a public key to push to this repository"
    end
  end

  def name=(*)
    super if name.nil? # Write once
  end

  def database_url
    env["DATABASE_URL"]
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
    system("DATABASE_URL=#{database_url} rake db:create")
  end

  def reload(*)
    load_app_env
    super
  end

  private
  def default_env
    Hash.new do |hash,key|
      case key
      when 'RAILS_ENV'
        hash['RACK_ENV']
      else
        { 'RACK_ENV' => 'production',
        'DATABASE_URL' => "postgres://localhost/#{name}" }[key]
      end
    end
  end

  def load_app_env
    @env = default_env
    Foreman::Env.new(app_env_path).entries do |name, value|
      env[name] = value
    end if name && File.exists?(app_env_path)
  end

  def write_app_env
    File.write(app_env_path, env.map {|k,v| "#{k}=#{v}\n" }.join)
  end

  def nginx_server_names
    (domains || '').split("\n")
  end

  def nginx_site_template
    template = File.join(Rails.root, 'lib/templates/nginx_site.erb')
    File.new(template).read
  end
end
