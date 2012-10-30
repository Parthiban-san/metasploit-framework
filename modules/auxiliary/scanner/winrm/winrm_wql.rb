##
# $Id$
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##


require 'msf/core'
require 'rex/proto/ntlm/message'


class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::WinRM
	include Msf::Auxiliary::Report


	include Msf::Auxiliary::Scanner

	def initialize
		super(
			'Name'           => 'WinRM WQL Query Runner',
			'Version'        => '$Revision$',
			'Description'    => %q{
				This module runs WQL queries against remote WinRM Services.
				Authentication is required. Currently only works with NTLM auth.
				},
			'Author'         => [ 'thelightcosine' ],
			'License'        => MSF_LICENSE
		)

		register_options(
			[
				OptString.new('WQL', [ true, "The WQL query to run", "Select Name,Status from Win32_Service" ]),
				OptString.new('USERNAME', [ true, "The username to authenticate as"]),
				OptString.new('PASSWORD', [ true, "The password to authenticate with"])
			], self.class)
	end


	def run_host(ip)
		unless accepts_ntlm_auth
			print_error "The Remote WinRM  server  (#{ip} does not appear to allow Negotiate(NTLM) auth"
			return
		end

		resp,c = send_request_ntlm(winrm_wql_msg(datastore['WQL']))
		if resp.nil?
			print_error "Got no reply from the server"
			return
		end
		if resp.code == 401
			print_error "Login Failure! Recheck the supplied credentials."
			return
		end

		unless resp.code == 200
			print_error "Got unexpected response from #{ip}: \n #{resp.to_s}"
			return
		end
		resp_tbl = parse_wql_response(resp)
		print_good resp_tbl.to_s
		path = store_loot("winrm.wql_results", "text/csv", ip, resp_tbl.to_csv, "winrm_wql_results.csv", "WinRM WQL Query Results")
		print_status "Results saved to #{path}"
	end



end
