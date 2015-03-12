package com.bb.mandolin.jmeter;

import java.io.File;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Map;

import org.apache.jmeter.config.Arguments;
import org.apache.jmeter.protocol.java.sampler.AbstractJavaSamplerClient;
import org.apache.jmeter.protocol.java.sampler.JavaSamplerContext;
import org.apache.jmeter.samplers.SampleResult;



public class ChefClientSampler extends AbstractJavaSamplerClient {

	File log = new File("/tmp/chef-client.log");
	SecureRandom sc = new SecureRandom();
	//possibly move this to 
	
		
	
	 
	public SampleResult runTest(JavaSamplerContext context) {
		// TODO Auto-generated method stub
		SampleResult testResults = new SampleResult();
		long l = sc.nextLong();
		//build the command string
		String []cmdLine = {"chef-client", 
				"-S", context.getParameter("CHEF_SERVER_URL"), 
				"-r", context.getParameter("RECIPE"),
				"-K", context.getParameter("VALIDATOR_PEM"),
				"-k", "/tmp/client" + l + ".pem" ,
				"-N", context.getParameter("NODE_PREFIX") + l,
				"-P", "/tmp/chef-client-" + l + ".pid"};
		
		ProcessBuilder pb = new ProcessBuilder(Arrays.asList(cmdLine));
		Map<String, String> env = pb.environment();
		env.put("PATH", context.getParameter("PATH"));
		 
		
		try {
			testResults.sampleStart();
			Process p = pb.start();
			//p.getOutputStream().
			int exit = p.waitFor();
			//System.out.println("Exit: " + exit);
		
			//Test for cookbook download NOT convergence
			byte []b = new byte[p.getInputStream().available()];
			p.getInputStream().read(b);
			String output = new String(b);
			boolean cb_downloaded =  output.contains(context.getParameter("SUCCESS_CRITERIA"));
			
		   
		   if (cb_downloaded ){
			   testResults.setResponseCodeOK();
			   testResults.setSuccessful(true);
		   	 
		   }else {
			   testResults.setSuccessful(false);
			   //TODO figure out the response code on process failure
			   testResults.setResponseCode("500");
		   }
		   testResults.setDataType( org.apache.jmeter.samplers.SampleResult.TEXT );
		   testResults.setResponseData(b);
		   
		}catch (Exception e) { //IO or Interrupted
			System.out.println("Command: " + cmdLine);
			e.printStackTrace();
			testResults.setSuccessful(false);
			            
            testResults.setResponseData(e.getMessage().getBytes());
            
            
		}
		
		testResults.sampleEnd();
		
		return testResults;
	}

	public Arguments getDefaultParameters() {
		Arguments args = new Arguments();
		
		args.addArgument("Version:","1.0.0");
		args.addArgument("PATH","/opt/chefdk/bin:/opt/chefdk/embedded/bin");
		args.addArgument("NODE_PREFIX","jmeter-node-");
		args.addArgument("CHEF_SERVER_URL","https://10.236.48.44");
		args.addArgument("RECIPE","recipe[iems_base]");
		args.addArgument("VALIDATOR_PEM","/home/marcus/ruby-workspace/.chef/chef-validator.pem");
		args.addArgument("NODE_PREFIX","jmeter-node-");
		args.addArgument("SUCCESS_CRITERIA","INFO: Loading cookbooks");
		
		return args;
	}
}
