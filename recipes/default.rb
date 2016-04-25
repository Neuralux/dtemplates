remote_file '/usr/bin/mo' do
  source node.mo_src
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end
