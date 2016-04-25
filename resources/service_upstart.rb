provides :dtemplate, platform: 'ubuntu' do |node|
  node['platform_version'].to_f < 15.10
end

property :instance_name, String, name_property: true
property :source, String, required: true
property :dsource, String, required: true
property :variables, Hash, default: {}
property :owner, String
property :group, String
property :mode, [String, Integer]
property :alias, String, required: true
property :dependencies, Array, default: []
property :token, String

action :start do
  create_init

  service "dtemplate_#{new_resource.alias}" do
    supports restart: true, status: true
    action :start
  end
end

action :stop do
  service "dtemplate_#{new_resource.alias}" do
    supports status: true
    action :stop
    only_if { ::File.exist?("/etc/init/dtemplate_#{new_resource.alias}.conf") }
  end
end

action :restart do
  action_stop
  action_start
end

action :disable do
  service "dtemplate_#{new_resource.alias}" do
    supports status: true
    action :disable
    only_if { ::File.exist?("/etc/init/dtemplate_#{new_resource.alias}.conf") }
  end
end

action :enable do
  create_init

  service "dtemplate_#{new_resource.alias}" do
    supports status: true
    action :enable
    only_if { ::File.exist?("/etc/init/dtemplate_#{new_resource.alias}.conf") }
  end
end

action_class.class_eval do
  def create_init
    ensure_dtemplate

    template "#{node.dtemplate.mustache_dir}/#{new_resource.alias}.mo" do
      source new_resource.source
      variables new_resource.variables
      owner 'root'
      group 'root'
      mode '0755'
    end

    template "#{node.dtemplate.defaults_dir}/#{new_resource.alias}" do
      source 'default_kv.erb'
      variables(
                map: new_resource.variables
                )
      cookbook 'dtemplate'
      owner 'root'
      group 'root'
      mode '0755'
    end

    template "/etc/init/dtemplate_#{new_resource.alias}.conf" do
      source 'init_upstart.erb'
      variables(
                instance: new_resource.alias,
                defaults: "#{node.dtemplate.defaults_dir}/#{new_resource.alias}",
                mustache: "#{node.dtemplate.defaults_dir}/#{new_resource.alias}.mo",
                src: new_resource.dsource,
                dest: new_resource.instance_name,
                mode: new_resource.mode,
                owner: new_resource.owner,
                group: new_resource.group,
                lock_dir: platform_lock_dir,
                token: new_resource.token
      )
      cookbook 'dtemplate'
      owner 'root'
      group 'root'
      mode '0644'
    end
  end
end
