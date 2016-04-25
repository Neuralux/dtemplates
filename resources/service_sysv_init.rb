provides :dtemplate, platform_family: 'suse'
provides :dtemplate, platform: 'amazon'

provides :dtemplate, platform: %w(redhat centos scientific oracle) do |node| # ~FC005
  node['platform_version'].to_f < 7.0
end

provides :dtemplate, platform: 'debian' do |node|
  node['platform_version'].to_i < 8
end

property :instance_name, String, name_property: true
property :source, String, required: true
property :dsource, String, required: true
property :variables, Hash, default: {}
property :owner, String
property :group, String
property :mode, [String, Integer]
property :alias, String, required: true

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
    only_if { ::File.exist?("/etc/init.d/dtemplate_#{new_resource.alias}.service") }
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
    only_if { ::File.exist?("/etc/init.d/dtemplate_#{new_resource.alias}.service") }
  end
end

action :enable do
  create_init

  service "dtemplate_#{new_resource.alias}" do
    supports status: true
    action :enable
    only_if { ::File.exist?("/etc/init.d/dtemplate_#{new_resource.alias}.service") }
  end
end

action_class.class_eval do
  def create_init
    ensure_dtemplate

    platform_lock_dir = value_for_platform_family(
      %w(rhel fedora suse) => '/var/lock/subsys',
      'debian' => '/var/lock',
      'default' => '/var/lock'
    )

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

    template "/etc/init.d/dtemplate_#{new_resource.alias}.service" do
      source 'init_sysv.erb'
      variables(
                instance: new_resource.alias,
                defaults: "#{node.dtemplate.defaults_dir}/#{new_resource.alias}",
                mustache: "#{node.dtemplate.defaults_dir}/#{new_resource.alias}.mo",
                src: new_resource.dsource,
                dest: new_resource.instance_name,
                mode: new_resource.mode,
                owner: new_resource.owner,
                group: new_resource.group,
                lock_dir: platform_lock_dir
      )
      cookbook 'dtemplate'
      mode '0755'
    end
  end
end
