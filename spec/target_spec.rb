require 'TBM/target'
require 'rspec'

describe TBM::Target do
	context "with name 'Foo'" do
		subject { TBM::Target.new( 'Foo','host','user' ) }

		it "should have name 'Foo'" do
			expect(subject).to have_name( 'Foo' )
		end

		it "should describe itself as 'Foo'" do
			expect(subject.to_s).to eq('Foo')
		end

		context "and aliases 'Bar', 'Baz'" do
			before do
				subject.add_alias('Bar')
				subject.add_alias('Baz')
			end

			it "should have name 'Foo'" do
				expect(subject).to have_name( 'Foo' )
			end

			it "should have name 'Bar'" do
				expect(subject).to have_name( 'Foo' )
			end

			it "should have name 'Baz'" do
				expect(subject).to have_name( 'Foo' )
			end

			it "should describe itself as 'Foo (Bar, Baz)'" do
				expect(subject.to_s).to eq('Foo (Bar, Baz)')
			end

		end
	end
end