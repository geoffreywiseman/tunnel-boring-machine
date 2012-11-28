require 'tunnel/config'
require 'tunnel/target'
require 'rspec'

describe Tunnel::Config do
	let( :path ) { File.expand_path( "~/.tunnels" ) }

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
			specify { subject.errors.should include_match(/No targets/) }
		end

		context "containing an array" do
			let(:config) { Array.new }
			it { should_not be_valid }
			specify { subject.errors.should include("Cannot parse tunnel configuration of type: Array") }
		end

		context "containing a Hash" do
			let(:config) { { 'target-name' => target } }

			context "of Arrays" do
				let(:target) { Array.new }
				specify { subject.errors.should include( "Cannot parse target 'target-name' (Array)" ) }
			end

			context "of Hashes" do
				let(:target) { Hash.new }

				context "w/o 'host'" do
					it { should_not be_valid }
					specify { subject.errors.should include_match(/no host found/) }
				end

				context "w/ 'host'" do
					let(:username) { 'bob' }
					let(:target) { { 'host' => 'gateway', 'username' => username } }

					it "should create target with host" do
						Tunnel::Target.should_receive(:new).with( 'target-name', target['host'], anything() )
						Tunnel::Config.new
					end

					it "should take username from config if specified" do
						Tunnel::Target.should_receive(:new).with( 'target-name', anything(), 'bob' )
						Tunnel::Config.new
					end

					it "should get current login if not specified" do
						target.delete('username')
						Etc.should_receive(:getlogin) { 'bill' }
						Tunnel::Target.should_receive(:new).with( 'target-name', anything(), 'bill' )
						Tunnel::Config.new
					end

					context "and no forward" do
						it { should_not be_valid }
						specify { subject.errors.should include_match(/no forward/) }
					end

					context "and a forward" do
						let(:target) { { 'host' => 'host', 'username' => 'username', 'forward' => forward } }
						let(:targetmock) { double(Tunnel::Target) }

						before do
							Tunnel::Target.stub(:new) { targetmock }
						end

						context "of 8080" do
							let(:forward) { 8080 }
							it "should forward port 8080 (no server specified)" do
								targetmock.should_receive( :forward_port ).with( 8080 )
								subject.should be_valid
							end
						end

						context "of [ 8000, 8443 ]" do
							let(:forward) { [8000,8443] }
							it "should forward ports 8080 and 8443" do
								targetmock.should_receive( :forward_port ).with( 8000 )
								targetmock.should_receive( :forward_port ).with( 8443 )
								subject.should be_valid
							end
						end

						context "of { alpha => 3000, beta => [ 8080, 8443 ] } ]" do
							let(:forward) { { 'alpha' => 3000, 'beta' => [ 8080, 8443 ] } }
							it "should forward port 3000 to alpha" do
								targetmock.should_receive( :forward_port ).with( 3000, 'alpha' )
								targetmock.stub( :forward_port ).with( anything(), 'beta' )
								subject.should be_valid
							end
							it "should forward ports 8080, 8443 to alpha" do
								targetmock.should_receive( :forward_port ).with( 8080, 'beta' )
								targetmock.should_receive( :forward_port ).with( 8443, 'beta' )
								targetmock.stub( :forward_port ).with( anything(), 'alpha' )
								subject.should be_valid
							end
						end

						it "should warn if forward is not whole number"
						it "should warn if port is negative"
						it "should warn if port contains characters"
						it "should warn if array contains invalid ports"
					end

					context "when target config has a an alias" do
						it "should treat string as single alias"
						it "should treat array as list of aliases"
						it "should warn with any other content"
					end
				end

			end

			it "should contain all targets specified"
		end
	end
end