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
							targetmock.stub( :host ) { 'host' }
						end

						context "of 8080" do
							let(:forward) { 8080 }
							it "should forward port 8080 on localhost" do
								targetmock.should_receive( :forward_port ).with( 8080, 'localhost' )
								subject.should be_valid
							end
						end

						context "of [ 8000, 8443 ]" do
							let(:forward) { [8000,8443] }
							it "should forward ports 8080 and 8443" do
								targetmock.should_receive( :forward_port ).with( 8000, 'localhost' )
								targetmock.should_receive( :forward_port ).with( 8443, 'localhost' )
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

						context "of 8000.5" do
							let(:forward) { 8000.5 }
							it { should_not be_valid }
							specify { subject.errors.should include_match(/Not sure how to handle forward .*: Float/) }
						end

						context "of -8080" do
							let(:forward) { -8080 }
							it { should_not be_valid }
							specify { subject.errors.should include_match(/Invalid port/) }
						end

						context "of 'blueberry'" do
							let(:forward) { 'blueberry' }
							it { should_not be_valid }
							specify { subject.errors.should include_match(/Not sure how to handle forward .*: String/) }
						end

						context "of 'blueberry'" do
							let(:forward) { [ 80.80, -443, 'blueberry' ] }
							it { should_not be_valid }
							specify { subject.errors.should include_match(/Invalid port/) }
						end

					end

					context "and an alias" do
						let(:target) { { 'host' => 'host', 'username' => 'username', 'forward' => 8080 } }
						let(:targetmock) { double(Tunnel::Target) }

						before do
							Tunnel::Target.stub(:new) { targetmock }
							targetmock.stub(:forward_port)
						end

						it "should treat string as single alias" do
							target['alias']= 'mr-smith'
							targetmock.should_receive( :alias ).with( 'mr-smith' )
							subject.should be_valid
						end

						it "should treat an array as a series of aliases" do
							target['alias']= 'mr-smith'
							targetmock.should_receive( :alias ).with( 'mr-smith' )
							subject.should be_valid
						end

						it "should warn with any other content" do
							target['alias'] = Hash.new
							subject.should_not be_valid
							subject.errors.should include_match( /Cannot parse alias/ )
						end
					end
				end

			end

			context "containing a hash of five targets" do
				let(:config) { { 'alpha' => { 'host' => 'host', 'forward' => 3001 }, 'beta' => { 'host' => 'host', 'forward' => 3002 }, 'gamma' => { 'host' => 'host', 'forward' => 3003 }, 'delta' => { 'host' => 'host', 'forward' => 3004 },
					'omega' => { 'host' => 'host', 'forward' => 3005 } } }
				it "should return all five targets specified" do
					subject.should be_valid
					subject.get_target( 'alpha' ).should be_instance_of(Tunnel::Target)
					subject.get_target( 'beta' ).should be_instance_of(Tunnel::Target)
					subject.get_target( 'gamma' ).should be_instance_of(Tunnel::Target)
					subject.get_target( 'delta' ).should be_instance_of(Tunnel::Target)
					subject.get_target( 'omega' ).should be_instance_of(Tunnel::Target)
				end
			end

		end
	end
end