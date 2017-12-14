require 'tbm'

include TBM

describe CommandLineInterface do

	let( :config ) { double( TBM::Config ) }
	subject { CommandLineInterface.new config }

	before do
		allow(TBM::ConfigParser).to receive( :parse ) { config }
		allow(config).to receive( :valid? ) { config_valid }
		allow(config).to receive( :errors ) { config_errors }
		stub_messages
	end

	context "without valid config" do
		let(:config_valid) { false }
		let(:config_errors) { ["Invalid Config"] }
		it "should print config errors" do
			CommandLineInterface.parse_and_run
			expect(@messages).to include_match(/Cannot parse config/)
			expect(@messages).to include_match(/Invalid Config/)
		end
	end

	context "with no parameters" do
		let(:config_valid) { true }

		before do
			ARGV.clear
			allow(config).to receive(:each_target).and_yield( 'alpha' ).and_yield( 'beta' )
		end

		it "should print syntax and targets" do
			CommandLineInterface.parse_and_run
			expect(@messages).to include_match( /SYNTAX/ )
			expect(@messages).to include_match( /alpha/ )
			expect(@messages).to include_match( /beta/ )
		end
	end

	context "with a single parameter" do
		let(:config_valid) { true }

		before do
			ARGV.clear.push( 'target-name' )
			allow(config).to receive(:get_target).with('target-name') { target }
		end

		context "matching a config target" do
			let(:target) { double Target }
			let(:thost) { 'target-host.example.com' }
			let(:tuser) { 'username' }
			let(:machine) { double( Machine ) }

			before do
				allow(target).to receive(:host) { thost }
				allow(target).to receive(:username) { tuser }
			end

			it "should start Tunnel Boring Machine" do
				allow(Machine).to receive(:new) { machine }
				expect(machine).to receive(:bore)
				CommandLineInterface.parse_and_run
			end
		end

		context "not matching a config target" do
			let(:target) { nil }

			before do
				allow(config).to receive(:each_target).and_yield( 'another-target' )
			end

			it "should say 'Cannot find target'" do
				CommandLineInterface.parse_and_run
				expect(@messages).to include_match( /Cannot find target/ )
			end

			it "should print target list" do
				CommandLineInterface.parse_and_run
				expect(@messages).to include_match( /another-target/ )
			end
		end
	end

	context "with multiple parameters" do
		let(:config_valid) { true }

		before do
			ARGV.clear.push( 'alpha', 'beta' )
			allow(config).to receive(:get_target).with('alpha') { alpha }
			allow(config).to receive(:get_target).with('beta') { beta }
		end

		context "matching configured targets with same host and user" do
			let(:alpha) { Target.new( 'alpha', 'host', 'username' ) }
			let(:beta) { Target.new( 'beta', 'host', 'username' ) }
			let(:machine) { double( Machine ) }

			it "should start boring machine" do
				allow(Machine).to receive(:new) { machine }
				expect(machine).to receive(:bore)
				CommandLineInterface.parse_and_run
			end
		end

		context "matching configured targets with different hosts" do
			let(:alpha) { double Target }
			let(:beta) { double Target }

			before do
				allow(alpha).to receive(:host) { 'host1' }
				allow(alpha).to receive(:username) { 'username' }
				allow(beta).to receive(:host) { 'host2' }
				allow(beta).to receive(:username) { 'username' }
			end

			it "should say 'Can't combine targets'" do
				CommandLineInterface.parse_and_run
				expect(@messages).to include_match(/Can't combine targets/)
			end
		end

		context "matching configured targets with different usernames" do
			let(:alpha) { double Target }
			let(:beta) { double Target }

			before do
				allow(alpha).to receive(:host) { 'host' }
				allow(alpha).to receive(:username) { 'username1' }
				allow(beta).to receive(:host) { 'host' }
				allow(beta).to receive(:username) { 'username2' }
			end

			it "should say 'Can't combine targets'" do
				CommandLineInterface.parse_and_run
				expect(@messages).to include_match(/Can't combine targets/)
			end
		end

		context "not all matching configured targets" do
			let(:alpha) { nil }
			let(:beta) { nil }

			before do
				allow(config).to receive(:each_target).and_yield( 'gamma' ).and_yield( 'delta' )
			end

			it "should say 'Cannot find target'" do
				CommandLineInterface.parse_and_run
				expect(@messages).to include_match(/Cannot find target/)
			end

			it "should print target list" do
				CommandLineInterface.parse_and_run
				expect(@messages).to include_match( /gamma/ )
				expect(@messages).to include_match( /delta/ )
			end
		end
	end


end