require_relative 'concurrent_client.rb'

class NewNodeRegistration < Load::Runner
  
  def node_prefix
    "load_testing_"
  end
  def task(ctx)
    
    begin
      Load::load_node "#{node_prefix}#{ctx.cur_num}"
    rescue
      Load::log.info "Starting NEW node registration #{ctx.cur_num}"
    end
        
    Load::client_register "#{node_prefix}#{ctx.cur_num}"
    
    #download cookbooks
    Load::download_cb("iems","1.6.3")

    Load::save_node "#{node_prefix}#{ctx.cur_num}"
    
  end

end

c = NewNodeRegistration.new
c.run_times(1)
c.shutdown