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
			allow(File).to receive( :file? ).with( path ) { false }
		end

		it { is_expected.not_to be_valid }
		specify { expect(subject.errors).to include_match /No configuration file found/ }
	end

	context "w/ config file" do
		before do
			allow(File).to receive( :file? ).with( path ) { true }
			expect(YAML).to receive( :load_file ).with( path ) { config }
		end

		context "containing no config" do
			let(:config) { Hash.new }
			it { is_expected.not_to be_valid }
			specify { expect(subject.errors).to include_match(/No gateways/) }
		end

		context "containing an array" do
			let(:config) { Array.new }
			it { is_expected.not_to be_valid }
			specify { expect(subject.errors).to include("Cannot parse TBM configuration of type: Array") }
		end

		context "containing a Hash" do
			let(:config) { { gateway => targets } }

			context "keyed by a gateway string" do
				let(:gateway) { "gateway" }
				let(:targets) { { 'web' => 80 } }
				it { is_expected.to be_valid }

				before do
					allow(Etc).to receive(:getlogin) { 'local-username' }
				end

				it "should contain a host with the specified gateway name" do
				  expect(subject.get_target('web').host).to eql('gateway')
				end

				it "should contain a host with the local username" do
				  expect(subject.get_target('web').username).to eql('local-username')
				end
			end

			context "keyed by a username@gateway string" do
				let(:gateway) { "remote-username@gateway.example.com" }
				let(:targets) { { 'web' => 80 } }
				it { is_expected.to be_valid }
				it "should contain a host with the specified gateway name" do
				  expect(subject.get_target('web').host).to eql('gateway.example.com')
				end
				it "should contain a host with the specified username" do
				  expect(subject.get_target('web').username).to eql('remote-username')
				end
			end

			context "keyed by a non-String" do
				let(:gateway) { Array.new }
				let(:targets) { Hash.new }
				specify { expect(subject.errors).to include_match( /Cannot parse gateway name/ ) }
			end

			context "with target hash of tunnels" do
				let(:gateway) { 'user@host' }
				let(:targets) { { 'target-name' => target } }

				context "with nil tunnel" do
					let(:target) { nil }
					specify { expect(subject.errors).to include_match(/No target config/) }
				end

				context "with parenthesized alias" do
					let(:targets) { { 'target-name (aka)' => 8080 } }
					it "should accept alias as name" do
						expect(subject).to be_valid
						expect(subject.get_target( 'aka' )).not_to be_nil
					end
				end

				context "with parenthesized aliases" do
					let(:targets) { { 'target-name (pseudo,nym)' => 8080 } }
					it "should accept alias as name" do
						expect(subject).to be_valid
						expect(subject.get_target( 'pseudo' )).not_to be_nil
						expect(subject.get_target( 'nym' )).not_to be_nil
					end
				end

				context "with target config of 8080" do
					let(:target) { 8080 }
					it "should forward port 8080" do
						expect(subject).to be_valid
						expect(subject.get_target('target-name')).to have_tunnel( :port => 8080, :remote_port => 8080, :remote_host => nil )
					end
				end

				context "with target config of 0" do
					let(:target) { 0 }
					specify { expect(subject.errors).to include( "Invalid port number 0" ) }
				end

				context "with target config of '8443'" do
					let(:target) { "8443" }
					it "should forward port 8443" do
						expect(subject).to be_valid
						target = expect(subject.get_target('target-name')).to have_tunnel( :port => 8443, :remote_port => 8443, :remote_host => nil )
					end
				end

				context "with target config of '77777'" do
					let(:target) { "77777" }
					specify { expect(subject.errors).to include( "Invalid port number 77777" ) }
				end

				context "with target config of '8080:80'" do
					let(:target) { "8080:80" }
					it "should map port 8080 to 80" do
						expect(subject).to be_valid
						target = expect(subject.get_target('target-name')).to have_tunnel( :port => 8080, :remote_port => 80, :remote_host => nil )
					end
				end

				context "with target config of '8080:prod:80'" do
					let(:target) { "8080:prod:80" }
					it "should map port 8080 to 80 on prod" do
						expect(subject).to be_valid
						target = expect(subject.get_target('target-name')).to have_tunnel( :port => 8080, :remote_port => 80, :remote_host => 'prod' )
					end
				end

				context "with target config of 'staging:8080'" do
					let(:target) { "staging:8080" }
					it "should forward port 8080 to staging" do
						puts subject.errors
						expect(subject).to be_valid
						target = expect(subject.get_target('target-name')).to have_tunnel( :port => 8080, :remote_port => 8080, :remote_host => 'staging' )
					end
				end

				context "with target config of [8080,8443]" do
					let(:target) { [8080,8443] }
					it "should forward ports 8080 and 8443" do
						puts subject.errors
						expect(subject).to be_valid
						target = expect(subject.get_target('target-name')).to have_tunnels( [ { :port => 8080 }, { :port => 8443 } ] )
					end
				end

				context "with target config of [3000,8080:80]" do
					let(:target) { [3000,"8080:80"] }
					it "should forward port 3000 and map 8080 to 80" do
						puts subject.errors
						expect(subject).to be_valid
						target = expect(subject.get_target('target-name')).to have_tunnels( [ { :port => 3000, :remote_port => 3000 }, { :port => 8080, :remote_port => 80 } ] )
					end
				end

				context "with Hash target config" do
					let(:target) { Hash.new }

					context "containing nothing" do
						specify { expect(subject.errors).to include_match(/no tunnels/) }
					end

					it "should forward port from 'tunnel' key" do
						target['tunnel'] = 3000
						expect(subject.get_target('target-name')).to have_tunnel( :port => 3000 )
					end

					it "should add alias from 'alias' key" do
						target['alias']='aka'
						expect(subject.get_target('target-name')).to have_name('aka')
					end

					it "should treat any other key as a remote host" do
						target['staging']=[1111,"2222:3333"]
						target['prod']=3306
						expect(subject.get_target('target-name')).to have_tunnels( [
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
				specify { expect(subject.errors).to include( "Cannot parse targets, expected Hash, received: String" ) }
			end

		end

	end
end

RSpec::Matchers.define :have_tunnel do |expected|
	match do |actual|
		expect(actual).not_to be_nil
		expect(actual.tunnels.size).to eql(1) 
		tunnel = actual.tunnels[0]
		expected.each do |k,v|
			expect(tunnel.send(k)).to eql(v)
		end
	end
	description do
		properties = expected.map{ |k,v| "#{k}=#{v}" }.join( ', ' )
		"have a tunnel with #{properties}"
	end
end

RSpec::Matchers.define :have_tunnels do |expected|
	match do |actual|
		expect(actual).not_to be_nil
		tunnels = actual.tunnels.sort_by { |t| t.port }
		expect(tunnels.size).to eql(expected.size)
		(0...expected.size).each do |index|
			tunnel = tunnels[index]
			properties = expected[index]
			properties.each do |k,v|
				expect(tunnel.send(k)).to eql(v)
			end
		end
	end
end
