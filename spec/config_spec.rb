require 'TBM/config_parser'
require 'TBM/config'
require 'TBM/target'
require 'rspec'

include TBM

describe ConfigParser do
	let( :path ) { File.expand_path( "~/.tbm" ) }
	subject { ConfigParser.parse }

	context "w/o config file" do
		before do
			stub_messages
			File.stub( :file? ).with( path ) { false }
		end

		it { should_not be_valid }
		specify { subject.errors.should include_match /No configuration file found/ }
	end

	context "w/ config file" do
		before do
			File.stub( :file? ).with( path ) { true }
			YAML.should_receive( :load_file ).with( path ) { config }
		end

		context "containing no config" do
			let(:config) { Hash.new }
			it { should_not be_valid }
			specify { subject.errors.should include_match(/No gateways/) }
		end

		context "containing an array" do
			let(:config) { Array.new }
			it { should_not be_valid }
			specify { subject.errors.should include("Cannot parse TBM configuration of type: Array") }
		end

		context "containing a Hash" do
			let(:config) { { gateway => targets } }

			context "keyed by a gateway string" do
				let(:gateway) { "gateway" }
				let(:targets) { { 'web' => 80 } }
				it { should be_valid }

				before do
					Etc.stub(:getlogin) { 'local-username' }
				end

				it "should contain a host with the specified gateway name" do
				  subject.get_target('web').host.should eql('gateway')
				end

				it "should contain a host with the local username" do
				  subject.get_target('web').username.should eql('local-username')
				end
			end

			context "keyed by a username@gateway string" do
				let(:gateway) { "remote-username@gateway.example.com" }
				let(:targets) { { 'web' => 80 } }
				it { should be_valid }
				it "should contain a host with the specified gateway name" do
				  subject.get_target('web').host.should eql('gateway.example.com')
				end
				it "should contain a host with the specified username" do
				  subject.get_target('web').username.should eql('remote-username')
				end
			end

			context "keyed by a non-String" do
				let(:gateway) { Array.new }
				let(:targets) { Hash.new }
				specify { subject.errors.should include_match( /Cannot parse gateway name/ ) }
			end

			context "with target hash of tunnels" do
				let(:gateway) { 'user@host' }
				let(:targets) { { 'target-name' => target } }

				context "with nil tunnel" do
					let(:target) { nil }
					specify { subject.errors.should include_match(/No target config/) }
				end

				context "with target config of 8080" do
					let(:target) { 8080 }
					it "should forward port 8080" do
						subject.should be_valid
						subject.get_target('target-name').should have_tunnel( :port => 8080, :remote_port => 8080, :remote_host => nil )
					end
				end

				context "with target config of 0" do
					let(:target) { 0 }
					specify { subject.errors.should include( "Invalid port number: 0" ) }
				end

				context "with target config of '8443'" do
					let(:target) { "8443" }
					it "should forward port 8443" do
						subject.should be_valid
						target = subject.get_target('target-name').should have_tunnel( :port => 8443, :remote_port => 8443, :remote_host => nil )
					end
				end

				context "with target config of '77777'" do
					let(:target) { "77777" }
					specify { subject.errors.should include( "Invalid port number: 77777" ) }
				end

				context "with target config of '8080:80'" do
					let(:target) { "8080:80" }
					it "should map port 8080 to 80" do
						subject.should be_valid
						target = subject.get_target('target-name').should have_tunnel( :port => 8080, :remote_port => 80, :remote_host => nil )
					end
				end

				context "with target config of '8080:prod:80'" do
					let(:target) { "8080:prod:80" }
					it "should map port 8080 to 80 on prod" do
						subject.should be_valid
						target = subject.get_target('target-name').should have_tunnel( :port => 8080, :remote_port => 80, :remote_host => 'prod' )
					end
				end

				context "with target config of 'staging:8080'" do
					let(:target) { "staging:8080" }
					it "should forward port 8080 to staging" do
						puts subject.errors
						subject.should be_valid
						target = subject.get_target('target-name').should have_tunnel( :port => 8080, :remote_port => 8080, :remote_host => 'staging' )
					end
				end

				context "with target config of [8080,8443]" do
					let(:target) { [8080,8443] }
					it "should forward ports 8080 and 8443" do
						puts subject.errors
						subject.should be_valid
						target = subject.get_target('target-name').should have_tunnels( [ { :port => 8080 }, { :port => 8443 } ] )
					end
				end

				context "with target config of [3000,8080:80]" do
					let(:target) { [3000,"8080:80"] }
					it "should forward port 3000 and map 8080 to 80" do
						puts subject.errors
						subject.should be_valid
						target = subject.get_target('target-name').should have_tunnels( [ { :port => 3000, :remote_port => 3000 }, { :port => 8080, :remote_port => 80 } ] )
					end
				end

				context "with Hash target config" do
					let(:target) { Hash.new }

					context "containing nothing" do
						specify { subject.errors.should include_match(/no tunnels/) }
					end

					it "should forward port from 'tunnel' key" do
						target['tunnel'] = 3000
						subject.get_target('target-name').should have_tunnel( :port => 3000 )
					end

					it "should add alias from 'alias' key" do
						target['alias']='aka'
						subject.get_target('target-name').should have_name('aka')
					end

					it "should treat any other key as a remote host" do
						target['staging']=[1111,"2222:3333"]
						target['prod']=3306
						subject.get_target('target-name').should have_tunnels( [
								{ :port => 1111, :remote_port => 1111, :remote_host => 'staging' },
								{ :port => 2222, :remote_port => 3333, :remote_host => 'staging' },
								{ :port => 3306, :remote_port => 3306, :remote_host => 'prod' },
							])
					end
				end
			end

			context "with a non-Hash value" do
				let(:gateway) { 'user@host' }
				let(:targets) { "Targets" }
				specify { subject.errors.should include( "Cannot parse targets, expected Hash, received: String" ) }
			end

		end

# target-details is a string (connection), array (array of connection) or hash (target-hash)
# connection is an integer or string, matching any of: <port> or <localport>:<remoteport> or <localport>:host:<remoteport>
# target-hash contains: alias, forward, remote-host
# alias is string or array of strings containing aliases for the tunnel name.
# forward contains a connection or array of connections
# remote-host maps to a remote connection or array of remote connections
# remote connection is an integer or a string in the following formats: <port>, <local-port>:<remote-port>

		# 			context "and no forward" do
		# 				it { should_not be_valid }
		# 				specify { subject.errors.should include_match(/no forward/) }
		# 			end

		# 			context "and a forward" do
		# 				let(:target) { { 'host' => 'host', 'username' => 'username', 'forward' => forward } }
		# 				let(:targetmock) { double(Tunnel::Target) }

		# 				before do
		# 					Tunnel::Target.stub(:new) { targetmock }
		# 					targetmock.stub( :host ) { 'host' }
		# 				end

		# 				context "of 8080" do
		# 					let(:forward) { 8080 }
		# 					it "should forward port 8080 on localhost" do
		# 						targetmock.should_receive( :forward_port ).with( 8080, nil )
		# 						subject.should be_valid
		# 					end
		# 				end

		# 				context "of [ 8000, 8443 ]" do
		# 					let(:forward) { [8000,8443] }
		# 					it "should forward ports 8080 and 8443" do
		# 						targetmock.should_receive( :forward_port ).with( 8000, nil )
		# 						targetmock.should_receive( :forward_port ).with( 8443, nil )
		# 						subject.should be_valid
		# 					end
		# 				end

		# 				context "of { alpha => 3000, beta => [ 8080, 8443 ] } ]" do
		# 					let(:forward) { { 'alpha' => 3000, 'beta' => [ 8080, 8443 ] } }
		# 					it "should forward port 3000 to alpha" do
		# 						targetmock.should_receive( :forward_port ).with( 3000, 'alpha' )
		# 						targetmock.stub( :forward_port ).with( anything(), 'beta' )
		# 						subject.should be_valid
		# 					end
		# 					it "should forward ports 8080, 8443 to alpha" do
		# 						targetmock.should_receive( :forward_port ).with( 8080, 'beta' )
		# 						targetmock.should_receive( :forward_port ).with( 8443, 'beta' )
		# 						targetmock.stub( :forward_port ).with( anything(), 'alpha' )
		# 						subject.should be_valid
		# 					end
		# 				end

		# 				context "of 8000.5" do
		# 					let(:forward) { 8000.5 }
		# 					it { should_not be_valid }
		# 					specify { subject.errors.should include_match(/Not sure how to handle forward .*: Float/) }
		# 				end

		# 				context "of -8080" do
		# 					let(:forward) { -8080 }
		# 					it { should_not be_valid }
		# 					specify { subject.errors.should include_match(/Invalid port/) }
		# 				end

		# 				context "of 'blueberry'" do
		# 					let(:forward) { 'blueberry' }
		# 					it { should_not be_valid }
		# 					specify { subject.errors.should include_match(/Not sure how to handle forward .*: String/) }
		# 				end

		# 				context "of 'blueberry'" do
		# 					let(:forward) { [ 80.80, -443, 'blueberry' ] }
		# 					it { should_not be_valid }
		# 					specify { subject.errors.should include_match(/Invalid port/) }
		# 				end

		# 			end

		# 			context "and an alias" do
		# 				let(:target) { { 'host' => 'host', 'username' => 'username', 'forward' => 8080 } }
		# 				let(:targetmock) { double(Tunnel::Target) }

		# 				before do
		# 					Tunnel::Target.stub(:new) { targetmock }
		# 					targetmock.stub(:forward_port)
		# 				end

		# 				it "should treat string as single alias" do
		# 					target['alias']= 'mr-smith'
		# 					targetmock.should_receive( :alias ).with( 'mr-smith' )
		# 					subject.should be_valid
		# 				end

		# 				it "should treat an array as a series of aliases" do
		# 					target['alias']= 'mr-smith'
		# 					targetmock.should_receive( :alias ).with( 'mr-smith' )
		# 					subject.should be_valid
		# 				end

		# 				it "should warn with any other content" do
		# 					target['alias'] = Hash.new
		# 					subject.should_not be_valid
		# 					subject.errors.should include_match( /Cannot parse alias/ )
		# 				end
		# 			end
		# 		end

		# 	end

		# 	context "containing a hash of five targets" do
		# 		let(:config) { { 'alpha' => { 'host' => 'host', 'forward' => 3001 }, 'beta' => { 'host' => 'host', 'forward' => 3002 }, 'gamma' => { 'host' => 'host', 'forward' => 3003 }, 'delta' => { 'host' => 'host', 'forward' => 3004 },
		# 			'omega' => { 'host' => 'host', 'forward' => 3005 } } }
		# 		it "should return all five targets specified" do
		# 			subject.should be_valid
		# 			subject.get_target( 'alpha' ).should be_instance_of(Tunnel::Target)
		# 			subject.get_target( 'beta' ).should be_instance_of(Tunnel::Target)
		# 			subject.get_target( 'gamma' ).should be_instance_of(Tunnel::Target)
		# 			subject.get_target( 'delta' ).should be_instance_of(Tunnel::Target)
		# 			subject.get_target( 'omega' ).should be_instance_of(Tunnel::Target)
		# 		end
		# 	end

	end
end

RSpec::Matchers.define :have_tunnel do |expected|
	match do |actual|
		actual.should_not be_nil
		actual.tunnels.size.should eql(1) 
		tunnel = actual.tunnels[0]
		expected.each do |k,v|
			tunnel.send(k).should eql(v)
		end
	end
	description do
		properties = expected.map{ |k,v| "#{k}=#{v}" }.join( ', ' )
		"have a tunnel with #{properties}"
	end
end

RSpec::Matchers.define :have_tunnels do |expected|
	match do |actual|
		actual.should_not be_nil
		actual.tunnels.size.should eql(expected.size) 
		(0...expected.size).each do |index|
			tunnel = actual.tunnels[index]
			properties = expected[index]
			properties.each do |k,v|
				tunnel.send(k).should eql(v)
			end
		end
	end
end
