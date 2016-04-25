property :instance_name, String, name_property: true
property :mustache_provider, String, default: 'mo'
property :source_path, String, default: 'https://raw.githubusercontent.com/tests-always-included/mo/master/mo'
property :install_path, String, default: '/usr/bin/mo'

action_class do
  def fetch_resource
    if new_resource.mustache_provider == 'mo'
      remote_file new_resource.install_path do
        source new_resource.source_path
        owner 'root'
        group 'root'
        mode 0755
        action :create
      end
    else
      Chef::Log.fatal("Unsupported mustache provider")
      raise
    end
  end

  def script_file
    cookbook_file node.dtemplate.script.path do
      source 'configure.sh'
      owner "dtemplate"
      group "dtemplate"
      mode 0755
      action :create
    end
  end
end

action :install do

  group "dtemplate" do
    action :create
  end

  user "dtemplate" do
    gid "dtemplate"
    shell '/bin/nologin'
    action :create
  end

  fetch_resource
  script_file
end
