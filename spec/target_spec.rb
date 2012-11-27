require 'tunnel/target'
require 'rspec'

describe Tunnel::Target do
	context "with name 'Foo'" do
		subject { Tunnel::Target.new( 'Foo','host','user' ) }

		it "should have name 'Foo'" do
			subject.should have_name( 'Foo' )
		end

		it "should describe itself as 'Foo'" do
			subject.to_s.should eq('Foo')
		end

		context "and aliases 'Bar', 'Baz'" do
			before do
				subject.alias('Bar')
				subject.alias('Baz')
			end

			it "should have name 'Foo'" do
				subject.should have_name( 'Foo' )
			end

			it "should have name 'Bar'" do
				subject.should have_name( 'Foo' )
			end

			it "should have name 'Baz'" do
				subject.should have_name( 'Foo' )
			end

			it "should describe itself as 'Foo (Bar, Baz)'" do
				subject.to_s.should eq('Foo (Bar, Baz)')
			end

		end
	end
end