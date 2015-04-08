#
# 
# Over-ridable values:
#:node_prefix => "load_test_",
#       :new_node_reg => 0,
#       :node_rereg => 0,
#       :pref_max_threads => 50,
#       :knife_bin => "/opt/chefdk/bin/knife",
#       :knife_config => "/etc/chef/knife.rb",
#       :log_level => Logger::INFO,
#       :chef_log_level => Logger::WARN
#
#
#  Can be accessed with Load::config[:key]

{
  :chef_log_level => Logger::WARN,
  :log_level => Logger::DEBUG,
  :knife_config => "/home/marcus/ruby-workspace/.chef/knife.rb",
  :pref_max_threads => 1

}
