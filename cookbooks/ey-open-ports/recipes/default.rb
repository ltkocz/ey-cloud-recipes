# port numbers that you wish to open up on your environment 
ports = [
  [21,'tcp', '0.0.0.0/0']
  [3306, 'tcp', "172.31.38.164"]
  [9312, 'tcp',  "172.31.38.164"]
  [11300, 'tcp',"172.31.38.164"]
]

chef_gem "aws" do
  action :install
end

# open ports via Aws
ruby_block "open up ports via EC2 security groups" do
  block do
    require 'aws'
      
    # build server
    region = node['engineyard']['environment']['region']
    server = "ec2.#{region}.amazonaws.com"

    # connect to EC2 via fog
    ec2 = Aws::Ec2.new( node['aws_secret_id'], node['aws_secret_key'],{:server => server })
    
    # find security group for environment
    env_name = node['engineyard']['environment']['name']
    sgroup = ec2.describe_security_groups.find{|e| e[:aws_group_name][/\Aey-#{env_name}-\d+/]}
    group = sgroup[:aws_group_name]
    # get ports that are already open
    open_ports = sgroup[:aws_perms].select{|p| p[:groups].empty?}.map{|e| (e[:from_port]..e[:to_port]).to_a}.flatten
    
    # authorize port if not already authorized
    ports.each do |port|
      if open_ports.include?(port)
        Chef::Log.info "Port #{port} is already open (open ports: #{open_ports.join(', ')})"
      else
        Chef::Log.info "Opening port #{port} to the outside world"
        ec2.authorize_security_group_IP_ingress(group, port[0],port[0], port[1],port[2])
      end
    end
  end
end