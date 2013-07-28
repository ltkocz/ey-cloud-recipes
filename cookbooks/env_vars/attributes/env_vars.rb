# Specify environment variables for Unicorn or Passenger here
#
# The example below will tune garbage collection for REE and Ruby 1.9.x and higher 
 
default[:env_vars] = {
  :BEANSTALK_URL => "beanstalk://172.31.33.216:11300",
}
