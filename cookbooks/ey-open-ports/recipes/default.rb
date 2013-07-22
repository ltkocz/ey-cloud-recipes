# port numbers that you wish to open up on your environment
front_env = "front"
ports = [
  {:port => 21, :protocol => 'tcp', :ip_range =>'0.0.0.0/0'},
  {:port =>3306, :protocol => 'tcp', :ip_range =>'front'},
  {:port =>9312, :protocol => 'tcp', :ip_range => "front"},
  {:port =>11300, :protocol => 'tcp', :ip_range =>"front"}
]

r = gem_package "aws-sdk" do
  action :nothing
end
r.runaction(:install)
Gem.clearpaths
require 'aws'
# open ports via Aws
ruby_block "open up ports via EC2 security groups" do
  block do
    # connect to EC2
    ec2 = AWS::EC2.new(:access_key_id => node['aws_secret_id'], :secret_access_key => node['aws_secret_key'],:region => node['engineyard']['environment']['region'])
    # find security group for environment
    env_name = node['engineyard']['environment']['name']
    security_groups = ec2.security_groups.filter("group-name","*#{env_name}*")
    front_group = ec2.security_groups.filter("group-name","*#{front_env}*").first
    security_groups.each do |security_group|
      open_ports = security_group.ingress_ip_permissions.select{|ip_permission| 
        ip_permission.groups.empty?
      }.map{|ip_permission|  
        "#{ip_permission.port_range.min}:#{e.protocol}"
      }.flatten.uniq
      ports.each do |port|
        if open_ports.include?("#{port[:port]}:#{port[:protocol]}")
          Chef::Log.info "Port #{port[:port]}:#{port[:protocol]} is already open (open ports: #{open_ports.join(', ')})"
        else
          target = port[:ip_range] == "front" ? front_group : port[:ip_range]
          Chef::Log.info "Opening port #{port[:port]}:#{port[:protocol]} to #{target.class.to_s == 'String' ? target : target.name}"
          security_group.authorize_ingress(port[:protocol].to_sym, port[:port],target)
        end
      end
    end
  end
end