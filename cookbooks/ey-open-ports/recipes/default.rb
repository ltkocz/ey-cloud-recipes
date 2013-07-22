# port numbers that you wish to open up on your environment 
ports = [
  {:port => 21, :protocol => 'tcp', :ip_range =>'0.0.0.0/0'},
  {:port =>3306, :protocol => 'tcp', :ip_range =>'172.31.38.164/32'},
  {:port =>9312, :protocol => 'tcp', :ip_range => "172.31.38.164/32"},
  {:port =>11300, :protocol => 'tcp', :ip_range =>"172.31.38.164/32"}
]

chef_gem "aws-sdk" do
  action :install
end

# open ports via Aws
ruby_block "open up ports via EC2 security groups" do
  block do
    require 'aws'
    # connect to EC2
    ec2 = AWS::EC2.new(:access_key_id => node['aws_secret_id'], :secret_access_key => node['aws_secret_key'],:region => node['engineyard']['environment']['region'])
    # find security group for environment
    env_name = node['engineyard']['environment']['name']
    security_groups = ec2.security_groups.filter("group-name","*#{env_name}*")
    
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
          Chef::Log.info "Opening port #{port[:port]}:#{port[:protocol]} to #{port[:ip_range]}"
          security_group.authorize_ingress(port[:protocol].to_sym, port[:port],port[:ip_range])
        end
      end
    end
  end
end