require_relative 'concurrent_client.rb'

class NewNodeRegistration < Load::Runner
  
  def node_prefix
    "load_testing_"
  end
  def task(ctx)
    
    
    Load::save_node "#{node_prefix}#{ctx.cur_num}"
    
  end

end

c = NewNodeRegistration.new
c.run_times(100)
c.shutdown